package io.gateway.filter;

import io.netty.handler.codec.http.FullHttpResponse;

public class HeaderHttpResponseFilter implements HttpResponseFilter {
    @Override
    public void filter(FullHttpResponse response) {

        response.headers().set("Date", "Tue, 08 Jun 2021 02:10:59 GMT");
    }
}
