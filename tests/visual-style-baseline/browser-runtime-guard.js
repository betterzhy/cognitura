(() => {
  "use strict";

  const usage = {
    guardInstallStatus: "FAIL",
    fetchCount: 0,
    xhrCount: 0,
    websocketCount: 0,
    eventsourceCount: 0,
    beaconCount: 0,
    storageCount: 0,
    cookieCount: 0,
    indexeddbCount: 0,
    cspViolationCount: 0,
  };
  Object.defineProperty(globalThis, "__vsbRuntimeUsage", {
    configurable: false,
    enumerable: false,
    writable: false,
    value: usage,
  });

  const forbidden = (counter) => {
    usage[counter] += 1;
    throw new Error("VSB_FORBIDDEN_RUNTIME_API");
  };
  const replaceGlobal = (name, counter) => {
    Object.defineProperty(globalThis, name, {
      configurable: true,
      writable: true,
      value: function VsbForbiddenRuntimeApi() {
        forbidden(counter);
      },
    });
  };

  try {
    globalThis.fetch = () => forbidden("fetchCount");
    replaceGlobal("XMLHttpRequest", "xhrCount");
    replaceGlobal("WebSocket", "websocketCount");
    replaceGlobal("EventSource", "eventsourceCount");
    navigator.sendBeacon = () => forbidden("beaconCount");

    for (const method of ["getItem", "setItem", "removeItem", "clear"]) {
      Object.defineProperty(Storage.prototype, method, {
        configurable: true,
        writable: true,
        value: function vsbForbiddenStorage() {
          forbidden("storageCount");
        },
      });
    }

    const cookieDescriptor = Object.getOwnPropertyDescriptor(
      Document.prototype,
      "cookie",
    );
    if (cookieDescriptor === undefined) {
      throw new Error("VSB_COOKIE_GUARD_UNAVAILABLE");
    }
    Object.defineProperty(Document.prototype, "cookie", {
      configurable: true,
      get() {
        forbidden("cookieCount");
      },
      set() {
        forbidden("cookieCount");
      },
    });

    if (globalThis.indexedDB === undefined) {
      throw new Error("VSB_INDEXEDDB_GUARD_UNAVAILABLE");
    }
    for (const method of ["open", "deleteDatabase"]) {
      Object.defineProperty(globalThis.indexedDB, method, {
        configurable: true,
        writable: true,
        value: function vsbForbiddenIndexedDb() {
          forbidden("indexeddbCount");
        },
      });
    }

    globalThis.addEventListener("securitypolicyviolation", () => {
      usage.cspViolationCount += 1;
    });
    usage.guardInstallStatus = "PASS";
  } catch {
    usage.guardInstallStatus = "FAIL";
  }
})();
