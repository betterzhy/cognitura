import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

public final class DocxFixtureMutator {
  private static final String W_NS =
      "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
  private static final String R_NS =
      "http://schemas.openxmlformats.org/officeDocument/2006/relationships";
  private static final String PACKAGE_REL_NS =
      "http://schemas.openxmlformats.org/package/2006/relationships";

  private DocxFixtureMutator() {
  }

  public static void main(String[] args) throws Exception {
    if (args.length != 2) {
      throw new IllegalArgumentException("expected <mutation> <docx>");
    }
    Path docx = Path.of(args[1]).toAbsolutePath().normalize();
    mutate(args[0], docx);
  }

  private static void mutate(String mutation, Path docx) throws Exception {
    Map<String, byte[]> entries = readEntries(docx);
    Document document = parse(entries.get("word/document.xml"));
    Document styles = parse(entries.get("word/styles.xml"));
    Element body = first(document, W_NS, "body");
    Map<String, String> styleNames = styleNames(styles);

    switch (mutation) {
      case "swap-headings" -> swapParagraphs(body, styleNames, true);
      case "swap-paragraphs" -> swapParagraphs(body, styleNames, false);
      case "remove-first-table" -> removeFirstTable(body);
      case "remove-first-image-reference" -> removeFirstImageReference(
          document,
          entries.get("word/_rels/document.xml.rels")
      );
      default -> throw new IllegalArgumentException(
          "unknown mutation " + mutation
      );
    }

    entries.put("word/document.xml", serialize(document));
    writeEntries(docx, entries);
  }

  private static Map<String, byte[]> readEntries(Path docx) throws IOException {
    LinkedHashMap<String, byte[]> entries = new LinkedHashMap<>();
    try (ZipFile zip = new ZipFile(docx.toFile(), StandardCharsets.UTF_8)) {
      for (ZipEntry entry : java.util.Collections.list(zip.entries())) {
        try (InputStream input = zip.getInputStream(entry)) {
          entries.put(entry.getName(), input.readAllBytes());
        }
      }
    }
    return entries;
  }

  private static void writeEntries(
      Path docx,
      Map<String, byte[]> entries
  ) throws IOException {
    Path temporary = Files.createTempFile(
        docx.getParent(),
        "cognitura-docx-mutation-",
        ".docx"
    );
    try {
      try (ZipOutputStream output = new ZipOutputStream(
          Files.newOutputStream(temporary),
          StandardCharsets.UTF_8
      )) {
        for (Map.Entry<String, byte[]> entry : entries.entrySet()) {
          ZipEntry zipEntry = new ZipEntry(entry.getKey());
          output.putNextEntry(zipEntry);
          output.write(entry.getValue());
          output.closeEntry();
        }
      }
      Files.move(
          temporary,
          docx,
          StandardCopyOption.REPLACE_EXISTING
      );
    } finally {
      Files.deleteIfExists(temporary);
    }
  }

  private static void swapParagraphs(
      Element body,
      Map<String, String> styleNames,
      boolean headings
  ) {
    List<Element> candidates = new ArrayList<>();
    for (Node child = body.getFirstChild(); child != null; child = child.getNextSibling()) {
      if (
          child instanceof Element paragraph &&
          W_NS.equals(paragraph.getNamespaceURI()) &&
          "p".equals(paragraph.getLocalName())
      ) {
        String styleName = paragraphStyleName(paragraph, styleNames);
        boolean heading = isHeading(styleName);
        if (
            heading == headings &&
            !paragraph.getTextContent().isBlank()
        ) {
          candidates.add(paragraph);
          if (candidates.size() == 2) {
            break;
          }
        }
      }
    }
    if (candidates.size() != 2) {
      throw new IllegalStateException("two paragraphs not found");
    }
    Element first = candidates.get(0);
    Element second = candidates.get(1);
    Node firstClone = first.cloneNode(true);
    Node secondClone = second.cloneNode(true);
    body.replaceChild(secondClone, first);
    body.replaceChild(firstClone, second);
  }

  private static void removeFirstTable(Element body) {
    for (Node child = body.getFirstChild(); child != null; child = child.getNextSibling()) {
      if (
          child instanceof Element element &&
          W_NS.equals(element.getNamespaceURI()) &&
          "tbl".equals(element.getLocalName())
      ) {
        body.removeChild(element);
        return;
      }
    }
    throw new IllegalStateException("table not found");
  }

  private static void removeFirstImageReference(
      Document document,
      byte[] relationshipsBytes
  ) {
    Document relationships = parse(relationshipsBytes);
    Set<String> imageIds = imageRelationshipIds(relationships);
    if (!removeImageAttribute(document.getDocumentElement(), imageIds)) {
      throw new IllegalStateException("image reference not found");
    }
  }

  private static Set<String> imageRelationshipIds(Document relationships) {
    java.util.HashSet<String> ids = new java.util.HashSet<>();
    NodeList nodes = relationships.getElementsByTagNameNS(
        PACKAGE_REL_NS,
        "Relationship"
    );
    for (int index = 0; index < nodes.getLength(); index++) {
      Element relationship = (Element) nodes.item(index);
      if (relationship.getAttribute("Type").endsWith("/image")) {
        ids.add(relationship.getAttribute("Id"));
      }
    }
    return ids;
  }

  private static boolean removeImageAttribute(
      Node node,
      Set<String> imageIds
  ) {
    if (node instanceof Element element) {
      NamedNodeMap attributes = element.getAttributes();
      for (int index = 0; index < attributes.getLength(); index++) {
        Node attribute = attributes.item(index);
        if (
            R_NS.equals(attribute.getNamespaceURI()) &&
            imageIds.contains(attribute.getNodeValue())
        ) {
          element.removeAttributeNS(
              attribute.getNamespaceURI(),
              attribute.getLocalName()
          );
          return true;
        }
      }
    }
    for (Node child = node.getFirstChild(); child != null; child = child.getNextSibling()) {
      if (removeImageAttribute(child, imageIds)) {
        return true;
      }
    }
    return false;
  }

  private static Map<String, String> styleNames(Document styles) {
    HashMap<String, String> names = new HashMap<>();
    NodeList nodes = styles.getElementsByTagNameNS(W_NS, "style");
    for (int index = 0; index < nodes.getLength(); index++) {
      Element style = (Element) nodes.item(index);
      String id = style.getAttributeNS(W_NS, "styleId");
      Element name = directChild(style, W_NS, "name");
      if (name != null) {
        names.put(id, name.getAttributeNS(W_NS, "val"));
      }
    }
    return names;
  }

  private static String paragraphStyleName(
      Element paragraph,
      Map<String, String> styleNames
  ) {
    Element properties = directChild(paragraph, W_NS, "pPr");
    Element style = properties == null
        ? null
        : directChild(properties, W_NS, "pStyle");
    if (style == null) {
      return "";
    }
    String id = style.getAttributeNS(W_NS, "val");
    return styleNames.getOrDefault(id, id);
  }

  private static boolean isHeading(String styleName) {
    String normalized = styleName.toLowerCase(Locale.ROOT);
    return normalized.startsWith("heading") || normalized.contains("标题");
  }

  private static Element directChild(
      Element parent,
      String namespace,
      String localName
  ) {
    for (Node child = parent.getFirstChild(); child != null; child = child.getNextSibling()) {
      if (
          child instanceof Element element &&
          namespace.equals(element.getNamespaceURI()) &&
          localName.equals(element.getLocalName())
      ) {
        return element;
      }
    }
    return null;
  }

  private static Element first(
      Document document,
      String namespace,
      String localName
  ) {
    NodeList nodes = document.getElementsByTagNameNS(namespace, localName);
    if (nodes.getLength() == 0) {
      throw new IllegalStateException(localName + " not found");
    }
    return (Element) nodes.item(0);
  }

  private static Document parse(byte[] bytes) {
    try {
      DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
      factory.setNamespaceAware(true);
      factory.setXIncludeAware(false);
      factory.setExpandEntityReferences(false);
      factory.setFeature(
          "http://apache.org/xml/features/disallow-doctype-decl",
          true
      );
      factory.setFeature(
          "http://xml.org/sax/features/external-general-entities",
          false
      );
      factory.setFeature(
          "http://xml.org/sax/features/external-parameter-entities",
          false
      );
      factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
      factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");
      return factory.newDocumentBuilder().parse(
          new ByteArrayInputStream(bytes)
      );
    } catch (Exception error) {
      throw new IllegalStateException(error);
    }
  }

  private static byte[] serialize(Document document) {
    try {
      TransformerFactory factory = TransformerFactory.newInstance();
      factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
      factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_STYLESHEET, "");
      var transformer = factory.newTransformer();
      transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
      transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
      ByteArrayOutputStream output = new ByteArrayOutputStream();
      transformer.transform(
          new DOMSource(document),
          new StreamResult(output)
      );
      return output.toByteArray();
    } catch (Exception error) {
      throw new IllegalStateException(error);
    }
  }
}
