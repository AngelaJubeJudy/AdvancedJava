package io.netty;

import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.socket.SocketChannel;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpServerCodec;

public class HttpInitializer extends ChannelInitializer<SocketChannel> {
	
	@Override
	public void initChannel(SocketChannel ch) {
		ChannelPipeline p = ch.pipeline();

		// 添加编码器
		p.addLast(new HttpServerCodec());
		//p.addLast(new HttpServerExpectContinueHandler());

		// 添加报文聚合器
		p.addLast(new HttpObjectAggregator(1024 * 1024));

		// 添加handler
		p.addLast(new HttpHandler());
	}
}
