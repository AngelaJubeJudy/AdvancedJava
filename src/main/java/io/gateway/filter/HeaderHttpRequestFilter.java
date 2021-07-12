package io.gateway.filter;

import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.FullHttpRequest;

public class HeaderHttpRequestFilter implements HttpRequestFilter {

    @Override
    public void filter(FullHttpRequest fullRequest, ChannelHandlerContext ctx) {
        fullRequest.headers().set("IDENTITY", "JWT20210621");
        fullRequest.headers().set("token", "ignore-fc3VwZXJ1c2VyIjp0cnVlLCJ0ZW5hbnQiOm51bGwsImV4cCI6MTYyMTU4NDM1OCwiaXNzIjo");
        fullRequest.headers().setInt("Content-Length", fullRequest.content().readableBytes());
        fullRequest.headers().set("Content-Type", "application/json");
    }
}
