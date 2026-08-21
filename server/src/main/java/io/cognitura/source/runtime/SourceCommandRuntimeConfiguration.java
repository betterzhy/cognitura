package io.cognitura.source.runtime;

import io.cognitura.source.application.command.SourceBinaryStore;
import io.cognitura.source.application.command.SourceCommandPersistencePort;
import io.cognitura.source.application.command.SourceCommandService;
import io.cognitura.source.application.command.TrustedRequestContext;
import io.cognitura.source.application.command.TrustedRequestContextProvider;
import io.cognitura.source.application.processing.ProcessingPublicationPort;
import io.cognitura.source.application.processing.ProcessingPublicationService;
import io.cognitura.source.persistence.JdbcProcessingPublicationPort;
import io.cognitura.source.persistence.SourceCommandMapper;
import io.cognitura.source.persistence.SourceCommandPersistenceAdapter;
import io.cognitura.source.storage.LocalContentAddressedSourceBinaryStore;
import java.nio.file.Path;
import java.time.Clock;
import java.util.Set;
import java.util.UUID;
import javax.sql.DataSource;
import org.apache.ibatis.session.SqlSessionFactory;
import org.flywaydb.core.Flyway;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.DependsOn;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

@Configuration(proxyBeanMethods = false)
@ConditionalOnProperty(
        prefix = "cognitura.source-command",
        name = "enabled",
        havingValue = "true")
public class SourceCommandRuntimeConfiguration {

    private static final String DOCX_MEDIA_TYPE =
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document";

    @Bean
    DataSource sourceCommandDataSource(Environment environment) {
        return new DriverManagerDataSource(
                required(environment, "jdbc-url"),
                required(environment, "jdbc-username"),
                required(environment, "jdbc-password"));
    }

    @Bean
    Flyway sourceCommandFlyway(DataSource sourceCommandDataSource) {
        Flyway flyway = Flyway.configure().dataSource(sourceCommandDataSource).load();
        flyway.migrate();
        return flyway;
    }

    @Bean
    @DependsOn("sourceCommandFlyway")
    SqlSessionFactory sourceCommandSqlSessionFactory(DataSource sourceCommandDataSource)
            throws Exception {
        var configuration = new org.apache.ibatis.session.Configuration();
        configuration.addMapper(SourceCommandMapper.class);
        var factory = new SqlSessionFactoryBean();
        factory.setDataSource(sourceCommandDataSource);
        factory.setConfiguration(configuration);
        return factory.getObject();
    }

    @Bean
    TrustedRequestContextProvider trustedRequestContextProvider(Environment environment) {
        TrustedRequestContext context = new TrustedRequestContext(
                required(environment, "workspace-id"),
                required(environment, "actor-id"));
        return () -> context;
    }

    @Bean
    SourceBinaryStore sourceBinaryStore(Environment environment) {
        Long maxBytes = environment.getRequiredProperty(
                property("max-upload-bytes"), Long.class);
        return new LocalContentAddressedSourceBinaryStore(
                Path.of(required(environment, "cas-root")),
                maxBytes,
                Set.of(DOCX_MEDIA_TYPE));
    }

    @Bean
    SourceCommandPersistencePort sourceCommandPersistencePort(
            SqlSessionFactory sourceCommandSqlSessionFactory) {
        return new SourceCommandPersistenceAdapter(sourceCommandSqlSessionFactory);
    }

    @Bean
    SourceCommandService sourceCommandService(
            SourceBinaryStore sourceBinaryStore,
            SourceCommandPersistencePort sourceCommandPersistencePort) {
        return new SourceCommandService(
                sourceBinaryStore,
                sourceCommandPersistencePort,
                () -> "source-document-" + UUID.randomUUID(),
                Clock.systemUTC());
    }

    @Bean
    ProcessingPublicationPort processingPublicationPort(DataSource sourceCommandDataSource) {
        return new JdbcProcessingPublicationPort(sourceCommandDataSource);
    }

    @Bean
    ProcessingPublicationService processingPublicationService(
            ProcessingPublicationPort processingPublicationPort) {
        return new ProcessingPublicationService(processingPublicationPort);
    }

    private static String required(Environment environment, String name) {
        String value = environment.getRequiredProperty(property(name));
        if (value.isBlank()) {
            throw new IllegalStateException("SOURCE_COMMAND_RUNTIME_PROPERTY_REQUIRED:" + name);
        }
        return value;
    }

    private static String property(String name) {
        return "cognitura.source-command." + name;
    }
}
