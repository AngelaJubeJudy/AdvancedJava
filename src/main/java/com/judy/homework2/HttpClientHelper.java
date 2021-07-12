package com.judy.homework2;

import org.apache.http.HttpEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.protocol.HTTP;
import org.apache.http.util.EntityUtils;

import java.io.IOException;
import java.util.Map;
import java.util.Set;

public class HttpClientHelper {

    public static CloseableHttpClient httpclient = HttpClients.createDefault();

    // GET 调用
    public static String getAsString(String url) throws IOException {
        HttpGet httpGet = new HttpGet(url);
        CloseableHttpResponse response1 = null;
        try {
            response1 = httpclient.execute(httpGet);
            response1.setHeader("Content-Type", "image/png");

            System.out.println(response1.getStatusLine());
            HttpEntity entity1 = response1.getEntity();
            return EntityUtils.toString(entity1, "UTF-8");
        } finally {
            if (null != response1) {
                response1.close();
            }
        }
    }


    // POST 调用
    public static String postAsJSON(String url, String json, Map<String, String> headers) throws IOException {
        HttpPost httpPost = new HttpPost(url);
        Set<String> keySet = headers.keySet();
        for (String name : keySet) {
            httpPost.setHeader(name, headers.get(name));
        }
        final String JSON_TYPE = "application/json;charset=UTF-8";
        httpPost.setHeader(HTTP.CONTENT_TYPE, JSON_TYPE);
        StringEntity entity = new StringEntity(json, "UTF-8");
        httpPost.setEntity(entity);

        CloseableHttpResponse response1 = null;
        try {
            response1 = httpclient.execute(httpPost);
            System.out.println(response1.getStatusLine());
            HttpEntity entity1 = response1.getEntity();
            return EntityUtils.toString(entity1, "UTF-8");
        } finally {
            if (null != response1) {
                response1.close();
            }
        }
    }

    public static void main(String[] args) throws Exception {

        String url = "http://10.200.2.187:8521/v1/tenants_management/download/300835829646276092?front=0&back=1&license=0";
        String text = HttpClientHelper.getAsString(url);
        System.out.println("url: " + url + " ; response: \n" + text);

    }
}
