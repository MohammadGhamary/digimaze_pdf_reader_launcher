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
    private String licSn;
    private String licKey;
    private String password;
    private String obfuscationKey;

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

    public String getLicSn() {
        return licSn;
    }

    public void setLicSn(String licSn) {
        this.licSn = licSn;
    }

    public String getLicKey() {
        return licKey;
    }

    public void setLicKey(String licKey) {
        this.licKey = licKey;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getObfuscationKey() {
        return obfuscationKey;
    }

    public void setObfuscationKey(String obfuscationKey) {
        this.obfuscationKey = obfuscationKey;
    }
}