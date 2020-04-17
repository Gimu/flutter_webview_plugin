import Flutter
import WebKit

@available(iOS 12, *)
extension WKWebViewConfiguration {
    
    @available(iOS 12, *)
    static func includeCookie(cookie:HTTPCookie, preferences:WKPreferences, completion: @escaping (WKWebViewConfiguration?) -> Void) {
        let config = WKWebViewConfiguration()
        config.preferences = preferences

        let dataStore = WKWebsiteDataStore.nonPersistent()

        DispatchQueue.main.async {
            let waitGroup = DispatchGroup()

            waitGroup.enter()
            dataStore.httpCookieStore.setCookie(cookie) {
                waitGroup.leave()
            }

            waitGroup.notify(queue: DispatchQueue.main) {
                config.websiteDataStore = dataStore
                completion(config)
            }
        }
    }
}

@available(iOS 12, *)
public class FlutterWebviewPlugin: NSObject, FlutterPlugin {
    var channel = FlutterMethodChannel()
    var viewController: UIViewController?
    var webView: WKWebView?
    var enableAppScheme = false
    var enableZoom = false
    var invalidUrlRegex: String?
    var javaScriptChannelNames: Set<AnyHashable>?

    public static func register(with registrar: FlutterPluginRegistrar) {
    //public static func register(withRegistrar registrar: (NSObjectProtocol & FlutterPluginRegistrar)?) {
        let channel = FlutterMethodChannel(name: "flutter_webview_plugin", binaryMessenger: registrar.messenger())
        let viewController = UIApplication.shared.delegate?.window??.rootViewController
        let instance = FlutterWebviewPlugin(viewController: viewController, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(viewController: UIViewController?, channel: FlutterMethodChannel) {
        super.init()
        self.viewController = viewController
        self.channel = channel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if ("launch" == call.method) {
            if self.webView == nil {
                self.initWebview(call)
            } else {
                //self.navigate(call)
            }
            result(nil)
        } else if ("close" == call.method) {
            self.closeWebView()
            result(nil)
        } else if ("eval" == call.method) {
            /*self.evalJavascript(call, completionHandler: { response in
                result(response)
            })*/
            result(nil)
        } else if ("resize" == call.method) {
            self.resize(call)
            result(nil)
        } else if ("reloadUrl" == call.method) {
            result(nil)
        } else if ("show" == call.method) {
            result(nil)
        } else if ("hide" == call.method) {
            result(nil)
        } else if ("stopLoading" == call.method) {
            result(nil)
        } else if ("cleanCookies" == call.method) {
        } else if ("back" == call.method) {
            result(nil)
        } else if ("forward" == call.method) {
            result(nil)
        } else if ("reload" == call.method) {
            result(nil)
        } else if ("canGoBack" == call.method) {
            result(nil)
        } else if ("canGoForward" == call.method) {
            result(nil)
        } else if ("cleanCache" == call.method) {
            //self.cleanCache(result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func resize(_ call: FlutterMethodCall) {
        if self.webView != nil {
            guard let args = call.arguments as? Dictionary<String, Any> else {
                print("No bueno")
                return
            }
            let rect = args["rect"] as! [AnyHashable : Any]
            let rc = self.parseRect(rect)
            self.webView?.frame = rc
        }
    }

    private func parseRect(_ rect: [AnyHashable : Any]?) -> CGRect {
        return CGRect(x: CGFloat((rect?["left"] as? NSNumber)?.doubleValue ?? 0.0), y: CGFloat((rect?["top"] as? NSNumber)?.doubleValue ?? 0.0), width: CGFloat((rect?["width"] as? NSNumber)?.doubleValue ?? 0.0), height: CGFloat((rect?["height"] as? NSNumber)?.doubleValue ?? 0.0))
    }

    private func closeWebView() {
        if self.webView != nil {
            self.webView?.stopLoading()
            self.webView?.removeFromSuperview()
            self.webView?.navigationDelegate = nil
            //webview?.removeObserver(self, forKeyPath: "estimatedProgress")
            self.webView = nil

            // manually trigger onDestroy
            self.channel.invokeMethod("onDestroy", arguments: nil)
        }
    }

    private func initWebview(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? Dictionary<String, Any> else {
            print("No bueno")
            return
        }
        let rect = args["rect"] as! [AnyHashable : Any]
        let cookie: String = args["cookie"] as? String ?? ""
        let url: String = args["url"] as! String

        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true

        var rc: CGRect
        if rect != nil {
            rc = self.parseRect(rect)
        } else {
            rc = self.viewController?.view.bounds ?? CGRect.zero
        }

        if (cookie == "") {
            // No cookie passed, init webview
            self.webView = WKWebView(frame: rc)
            let presentedViewController = self.viewController?.presentedViewController
            let currentViewController: UIViewController? = presentedViewController ?? self.viewController as? UIViewController
            currentViewController?.view.addSubview(self.webView!)
            // Load URL
            let request = URLRequest(url: URL(string: url)!)
            self.webView!.load(request)
            return
        }

        let cookieArray = cookie.components(separatedBy: "=")
        let realCookie = HTTPCookie(properties: [
            .path : "/",
            .originURL : url,
            .name : cookieArray[0],
            .value : cookieArray[1].replacingOccurrences(of: "; path", with: "")
        ])

        if realCookie != nil {
            WKWebViewConfiguration.includeCookie(cookie: realCookie!, preferences: preferences, completion: {
            [weak self] config in
                if let `self` = self {
                    if let configuration = config {
                        // Init webview
                        self.webView = WKWebView(frame: rc, configuration: configuration)
                        let presentedViewController = self.viewController?.presentedViewController
                        let currentViewController: UIViewController? = presentedViewController ?? self.viewController as? UIViewController
                        currentViewController?.view.addSubview(self.webView!)
                        // Load URL
                        let request = URLRequest(url: URL(string: url)!)
                        self.webView!.load(request)
                    }
                }
            });
        }
            /*.domain: COOKIE_DOMAIN,
            .path: "/",
            .name: COOKIE_NAME,
            .value: myCookieValue,
            .secure: "TRUE",
            .expires: NSDate(timeIntervalSinceNow: 3600)*/




        /*let clearCache = call.arguments["clearCache"] as? NSNumber
        let clearCookies = call.arguments["clearCookies"] as? NSNumber
        let hidden = call.arguments["hidden"] as? NSNumber
        enableAppScheme = call.arguments["enableAppScheme"]
        let userAgent = call.arguments["userAgent"] as? String
        let withZoom = call.arguments["withZoom"] as? NSNumber
        let scrollBar = call.arguments["scrollBar"] as? NSNumber
        let withJavascript = call.arguments["withJavascript"] as? NSNumber
        invalidUrlRegex = call.arguments["invalidUrlRegex"]
        javaScriptChannelNames = Set<AnyHashable>()

        let userContentController = WKUserContentController()

        if userAgent != NSNull() {
            UserDefaults.standard.register(defaults: [
            "UserAgent": userAgent
            ])
        }

        let preferences = WKPreferences()
        if withJavascript.boolValue {
            preferences.javaScriptEnabled = true
            preferences.javaScriptCanOpenWindowsAutomatically = true
        } else {
            preferences.javaScriptEnabled = false
            preferences.javaScriptCanOpenWindowsAutomatically = false
        }
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.preferences = preferences

        enableZoom = withZoom.boolValue

        // Mandatory cookie
        let cookie = call.arguments["cookie"] as? String
        let url = call.arguments["url"] as? String
        if #available(iOS 11, *) {
            // REQUIRES iOS 11.0+
            // @docs WKWebViewConfiguration is only used when a web view is first initialized. You cannot use this class to change the web view's configuration after it has been created.
            //WKHTTPCookieStore *cookieStore = self.webview?.configuration.websiteDataStore.httpCookieStore;

            // Split string cookie to get name/value
            let cookieArray = cookie.components(separatedBy: "=")
            print("SET COOKIE FIRST TIME")

            // Create cookie object
            let properties = [
                .path : "/",
                .originURL : url,
                .name : cookieArray[0],
                .value : cookieArray[1].replacingOccurrences(of: "; path", with: "")
            ]

            let realCookie = HTTPCookie(properties: properties)
            if realCookie != nil {
                configuration.websiteDataStore.httpCookieStore.setCookie(realCookie, completionHandler: {
                    // Init webview
                    self.webview = WKWebView(frame: rc, configuration: configuration)
                    self.webview?.uiDelegate = self
                    self.webview?.navigationDelegate = self
                    self.webview?.scrollView.delegate = self
                    self.webview?.hidden = hidden.boolValue
                    self.webview?.scrollView.showsHorizontalScrollIndicator = scrollBar.boolValue
                    self.webview?.scrollView.showsVerticalScrollIndicator = scrollBar.boolValue
                    self.webview?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
                
                    let presentedViewController = self.viewController?.presentedViewController
                    let currentViewController: UIViewController? = presentedViewController ?? self.viewController as? UIViewController
                    currentViewController?.view.addSubview(webview)
                    // Load page
                    navigate(call)
                });
            } else {
                // TODO? IOS < 12
            }
        }*/
    }

    /*public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let xDirection = [
            "xDirection": NSNumber(value: Float(scrollView.contentOffset.x))
        ]
        self.channel.invokeMethod("onScrollXChanged", arguments: xDirection)

        let yDirection = [
            "yDirection": NSNumber(value: Float(scrollView.contentOffset.y))
        ]
        self.channel.invokeMethod("onScrollYChanged", arguments: yDirection)
    }

    func navigate(_ call: FlutterMethodCall) {
        if self.webview != nil {
            let url = call?.arguments["url"] as? String
            let withLocalUrl = call?.arguments["withLocalUrl"] as? NSNumber
            if withLocalUrl?.boolValue ?? false {
                let htmlUrl = URL(fileURLWithPath: url ?? "", isDirectory: false)
                let localUrlScope = call?.arguments["localUrlScope"] as? String
                if #available(iOS 9.0, *) {
                    if localUrlScope == nil {
                        self.webview?.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
                    } else {
                        let scopeUrl = URL(fileURLWithPath: localUrlScope ?? "")
                        self.webview?.loadFileURL(htmlUrl, allowingReadAccessTo: scopeUrl)
                    }
                } else {
                    throw "not available on version earlier than ios 9.0"
                }
            } else {
                var request: NSMutableURLRequest? = nil
                if let url = URL(string: url) {
                    request = NSMutableURLRequest(url: url)
                }
                let headers = call.arguments["headers"] as? [AnyHashable : Any]

                if headers != nil {
                    request?.allHTTPHeaderFields = headers as? [String : String]
                }

                if let request = request {
                    self.webview?.loadRequest(request)
                }
            }
        }
    }

    func evalJavascript(_ call: FlutterMethodCall, completionHandler: ((_ response: String?) -> Void)? = nil) {
        if webview != nil {
            let code = call?.arguments["code"] as? String
            webview?.evaluateJavaScript(code ?? "", completionHandler: { response, error in
                completionHandler?("\(response ?? "")")
            })
        } else {
            completionHandler?(nil)
        }
    }

    func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") && object == webview {
            self.channel.invokeMethod("onProgressChanged", arguments: [
            "progress": NSNumber(value: webview?.estimatedProgress)
            ])
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }*

    func reloadUrl(_ call: FlutterMethodCall) {
        if webview != nil {
            let url = call?.arguments["url"] as? String
            var request: NSMutableURLRequest? = nil
            if let url1 = URL(string: url ?? "") {
                request = NSMutableURLRequest(url: url1)
            }
            let headers = call?.arguments["headers"] as? [AnyHashable : Any]

            if headers != nil {
                request?.allHTTPHeaderFields = headers as? [String : String]
            }

            if let request = request {
                webview?.loadRequest(request)
            }
        }
    }

    func cleanCookies(_ result: FlutterResult) {
        if webview != nil {
            URLSession.shared.reset(completionHandler: {
            })
            if #available(iOS 9.0, *) {
                let websiteDataTypes = Set<AnyHashable>([WKWebsiteDataTypeCookies])
                let dataStore = WKWebsiteDataStore.default()

                let deleteAndNotify: (([WKWebsiteDataRecord]?) -> Void)? = { cookies in
                        if let cookies = cookies {
                            dataStore.removeData(ofTypes: websiteDataTypes, for: cookies, completionHandler: {
                                result(nil)
                            })
                        }
                    }

                if let deleteAndNotify = deleteAndNotify {
                    dataStore.fetchDataRecords(ofTypes: websiteDataTypes, completionHandler: deleteAndNotify)
                }
            } else {
            // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
            print("Clearing cookies is not supported for Flutter WebViews prior to iOS 9.")
            }
        }
    }

    func cleanCache(_ result: FlutterResult) {
        if webview != nil {
            if #available(iOS 9.0, *) {
                let cacheDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
                let dataStore = WKWebsiteDataStore.default()
                let dateFrom = Date(timeIntervalSince1970: 0)

                dataStore.removeData(ofTypes: cacheDataTypes, modifiedSince: dateFrom, completionHandler: {
                    result(nil)
                })
            } else {
                // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
                print("Clearing cache is not supported for Flutter WebViews prior to iOS 9.")
            }
        }
    }

    func stopLoading() {
        if webview != nil {
            webview?.stopLoading()
        }
    }

    func back() {
        if webview != nil {
            webview?.goBack()
        }
    }

    func onCanGoBack(_ call: FlutterMethodCall, result: FlutterResult) {
        let canGoBack = webview?.canGoBack
        result(NSNumber(value: canGoBack!))
    }

    func onCanGoForward(_ call: FlutterMethodCall, result: FlutterResult) {
        let canGoForward = webview?.canGoForward
        result(NSNumber(value: canGoForward!))
    }

    func forward() {
        if webview != nil {
            webview?.goForward()
        }
    }

    func reload() {
        if webview != nil {
            webview?.reload()
        }
    }

    func checkInvalidUrl(_ url: URL?) -> Bool {
        let urlString = url != nil ? url?.absoluteString : nil
        if !invalidUrlRegex == NSNull() && urlString != nil {
            var error: Error? = nil
            var regex: NSRegularExpression? = nil
            do {
                regex = try NSRegularExpression(pattern: invalidUrlRegex, options: .caseInsensitive)
            } catch {
            }
            let match = regex?.firstMatch(in: urlString ?? "", options: [], range: NSRange(location: 0, length: urlString?.count ?? 0))
            return match != nil
        } else {
            return false
        }
    }

    // MARK: -- WkWebView Delegate
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let data : [String:Any] = [
            "url": navigationAction.request.url?.absoluteString ?? "",
            "type": "shouldStart",
            "navigationType": NSNumber(value: navigationAction.navigationType.rawValue)
        ]
        self.channel.invokeMethod("onState", arguments: data)

        if navigationAction.navigationType == .backForward {
            self.channel.invokeMethod("onBackPressed", arguments: nil)
        } else {
            let data = [
                "url": navigationAction.request.url?.absoluteString ?? ""
            ]
            self.channel.invokeMethod("onUrlChanged", arguments: data)
        }
        if enableAppScheme || ((webView.url?.scheme == "http") || (webView.url?.scheme == "https") || (webView.url?.scheme == "about") || (webView.url?.scheme == "file")) {
            decisionHandler(WKNavigationActionPolicy.allow)
        } else {
            decisionHandler(WKNavigationActionPolicy.cancel)
        }
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame?.isMainFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
       self.channel.invokeMethod("onState", arguments: [
        "type": "startLoad",
        "url": webView.url?.absoluteString ?? ""
        ])
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let url = webView.url == nil ? "?" : webView.url?.absoluteString

        self.channel.invokeMethod("onHttpError", arguments: [
        "code": String(format: "%ld", (error as NSError).code),
        "url": url ?? ""
        ])
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.channel.invokeMethod("onState", arguments: [
        "type": "finishLoad",
        "url": webView.url?.absoluteString ?? ""
        ])
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.channel.invokeMethod("onHttpError", arguments: [
        "code": String(format: "%ld", (error as NSError).code),
        "error": error.localizedDescription
        ])
    }

    @override
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if (navigationResponse.response is HTTPURLResponse) {
            let response = navigationResponse.response as? HTTPURLResponse

            if (response?.statusCode ?? 0) >= 400 {
                channel.invokeMethod("onHttpError", arguments: [
                "code": String(format: "%ld", response?.statusCode ?? 0),
                "url": webView.url?.absoluteString ?? ""
                ])
            }
        }
        decisionHandler(WKNavigationResponsePolicyAllow)
    }

    // MARK: -- UIScrollViewDelegate
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.pinchGestureRecognizer?.isEnabled != enableZoom {
            scrollView.pinchGestureRecognizer?.isEnabled = enableZoom
        }
    }

    // MARK: -- WKUIDelegate
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: { action in
            completionHandler()
        }))
        self.viewController?.present(alert, animated: true)
    }

    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { action in
            completionHandler(false)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { action in
            completionHandler(true)
        }))
        self.viewController?.present(alert, animated: true)
    }

    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = prompt
            textField.isSecureTextEntry = false
            textField.text = defaultText
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { action in
            completionHandler(nil)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { action in
            completionHandler(alert.textFields?.first?.text ?? "")
        }))
        self.viewController?.present(alert, animated: true)
    }*/
}
