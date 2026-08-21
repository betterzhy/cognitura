package io.cognitura.source.application.command;

@FunctionalInterface
public interface TrustedRequestContextProvider {

    TrustedRequestContext currentContext();
}
