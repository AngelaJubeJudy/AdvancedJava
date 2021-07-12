package io.gateway.filter;

import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.FullHttpRequest;

public class HeaderHttpRequestFilter implements HttpRequestFilter {

    @Override
    public void filter(FullHttpRequest fullRequest, ChannelHandlerContext ctx) {
        fullRequest.headers().set("IDENTITY", "JWT20210621");
        fullRequest.headers().set("token", "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1OTI4OTA4MDUsImlzcyI6Imh0dHA6Ly8yMXZjbG91ZC5jb20iLCJ1c2VyX2lkIjoiOGI5ZTkxMDE4ZDgyNDBmODgxNWMwMTRlYTllNWI5NzYiLCJjb21wYW55X29iaiI6IjVkZDc4ZDE0ZjRmM2E0ZjE2MDlkNTczOSJ9.QSQ3al8jricAxX_AyJPpo_gQCi1fJSLj8GUAP6skEJc");
        fullRequest.headers().setInt("Content-Length", fullRequest.content().readableBytes());
        fullRequest.headers().set("Content-Type", "application/json");
    }
}
