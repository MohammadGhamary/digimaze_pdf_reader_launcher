package com.vnegar.digimaze_pdf_reader_launcher.models;

import java.io.Serial;
import java.io.Serializable;

public class PDFParams implements Serializable {
    @Serial
    private static final long serialVersionUID = 1L;

    private String deviceUID;
    private String userAuthToken;
    private String logApiUrl;
    private String appVersion;
    private String bookId;
    private boolean isMobile;
    private String type;
    private String filePath;
    private String title;
    private String x1;
    private String x2;
    private String x3;
    private String x4;

    public String getDeviceUID() {
        return deviceUID;
    }

    public void setDeviceUID(String deviceUID) {
        this.deviceUID = deviceUID;
    }

    public String getUserAuthToken() {
        return userAuthToken;
    }

    public void setUserAuthToken(String userAuthToken) {
        this.userAuthToken = userAuthToken;
    }

    public String getLogApiUrl() {
        return logApiUrl;
    }

    public void setLogApiUrl(String logApiUrl) {
        this.logApiUrl = logApiUrl;
    }

    public String getAppVersion() {
        return appVersion;
    }

    public void setAppVersion(String appVersion) {
        this.appVersion = appVersion;
    }

    public String getBookId() {
        return bookId;
    }

    public void setBookId(String bookId) {
        this.bookId = bookId;
    }

    public boolean isMobile() {
        return isMobile;
    }

    public void setMobile(boolean mobile) {
        isMobile = mobile;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getFilePath() {
        return filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getX1() {
        return x1;
    }

    public void setX1(String x1) {
        this.x1 = x1;
    }

    public String getX2() {
        return x2;
    }

    public void setX2(String x2) {
        this.x2 = x2;
    }

    public String getX3() {
        return x3;
    }

    public void setX3(String x3) {
        this.x3 = x3;
    }

    public String getX4() {
        return x4;
    }

    public void setX4(String x4) {
        this.x4 = x4;
    }
}