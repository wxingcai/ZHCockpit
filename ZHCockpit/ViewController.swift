//
//  ViewController.swift
//  ScreenShield
//
//  Created by apple on 2023/11/20.
//

import UIKit
import WebKit
import Alamofire

class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    
    var bgmView: UIImageView!
    var webView: WKWebView!
    var statusHeight: CGFloat = 0
    var currentUrl = ""
    var topTile = ""
    var naviBarFlag = ""
    var hidenNaviBar = true
    var naviBarView: UIView!
    var titleLbl: UILabel!
    var backBtn: UIButton!
    var topBack: CAGradientLayer!
    var watermarkWord = ""
    
    deinit {
        deleteWebCache()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        webView.configuration.userContentController.add(self, name: "getAppInfo")
        webView.configuration.userContentController.add(self, name: "openPage")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "getAppInfo")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "openPage")
    }
    
    func deleteWebCache() {
        //清除web缓存信息
        let websiteDataTypes = Set(arrayLiteral: WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache)
        let dateFrom = Date.init(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom, completionHandler: {})
    }
    
    override func loadView() {
        super.loadView()
        view = ScreenShieldView.create(frame: UIScreen.main.bounds)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.navigationController?.isNavigationBarHidden = true
        
        if !hidenNaviBar {
            self.loadNaviBarView()
        }
        self.loadWKWebView()
        
        if !isGetLatestVersion {
            self.requestLatestVersion()
            isGetLatestVersion = true
        }
        statusHeight = 0
        if !hidenNaviBar {
            statusHeight = statusBarHeight + 44
        }
        self.updateConstraints()
        
        let userDefaults = UserDefaults.standard
        let firstInstall = userDefaults.object(forKey: "firstInstall")
        if firstInstall == nil {
            let netManager = AFNetworkReachabilityManager.shared()
            netManager.setReachabilityStatusChange { status in
                if (status == .reachableViaWWAN || status == .reachableViaWiFi) {
                    if let h5Url = URL(string: self.currentUrl) {
                        self.webView.load(URLRequest(url: h5Url))
                    }
                    userDefaults.setValue("installed", forKey: "firstInstall")
                    userDefaults.synchronize()
                    netManager.stopMonitoring()
                }
            }
            netManager.startMonitoring()
        }
    }
    
    func loadWKWebView() {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        config.userContentController = userContentController;
        
        // 禁止网页本身自带的长按
        let noneSelectScript1 = WKUserScript.init(source: "document.documentElement.style.webkitUserSelect='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let noneSelectScript2 = WKUserScript.init(source: "document.documentElement.style.webkitUserSelect='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        //let noneSelectScriptStr = "var metaScript = document.createElement('meta'); metaScript.name = 'viewport'; metaScript.content=\"width=device-width, initial-scale=1.0,maximum-scale=1.0, minimum-scale=1.0, user- scalable=no\"; document.head.appendChild(metaScript);"
        //let noneSelectScript3 = WKUserScript.init(source: noneSelectScriptStr,injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(noneSelectScript1)
        userContentController.addUserScript(noneSelectScript2)
        //userContentController.addUserScript(noneSelectScript3)
        webView = WKWebView.init(frame: .zero, configuration: config)
        
        if currentUrl == "" {
            currentUrl = App_MainUrl
        }
        if let h5Url = URL(string: currentUrl) {
            webView.load(URLRequest(url: h5Url))
        }
        
        webView.navigationDelegate = self
        //webView.scrollView.bounces = false
        webView.scrollView.decelerationRate = .fast
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(webView)
        
        bgmView = UIImageView()
        bgmView.alpha = 0.3
        bgmView.backgroundColor = .gray
        bgmView.isHidden = true
        view.addSubview(bgmView)
    }
        
    func loadNaviBarView() {
        naviBarView = UIView.init()
        naviBarView.backgroundColor = UIColor.white
        view.addSubview(naviBarView)
        
        backBtn = UIButton(type: .custom)
        backBtn.setImage(UIImage(named: "back2"), for: .normal)
        backBtn.addTarget(self, action: #selector(goback), for: .touchUpInside)
        naviBarView.addSubview(backBtn)
        
        titleLbl = UILabel.init()
        titleLbl.textColor = UIColor.hexStringToColor(hex: "#333333", alpha: 1)
        titleLbl.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLbl.textAlignment = .center
        titleLbl.text = topTile
        naviBarView.addSubview(titleLbl)
    }
    
    @objc func goback() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let tempUrl = navigationAction.request.url?.absoluteString {
            print("currentUrl ====  ", tempUrl)
        }
        decisionHandler(.allow)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.name)
        if message.name == "getAppInfo" {
            if let messageStr = message.body as? String {
                let messageDic = self.getDictionaryFromJSONString(jsonString: messageStr)
                watermarkWord = "\(messageDic["username"] ?? "")"
                let _img = createWatermarkFor(Text: watermarkWord, andFullSize:CGSize(width: view.bounds.width, height: view.bounds.height))
                bgmView.backgroundColor = UIColor(patternImage: _img)
                bgmView.isHidden = false
            }
            //获取本地版本号
            let infoDictionary = Bundle.main.infoDictionary
            let appVersion = infoDictionary!["CFBundleShortVersionString"] as! String
            //获取手机UUID
            let identifierNumber = UIDevice.current.identifierForVendor?.uuidString
            print("APP_UUID : \(identifierNumber ?? "")")
            
            let appInfos = NSMutableDictionary.init()
            appInfos.setValue("V\(appVersion)", forKey: "versioncode")
            
            let jsonString = getJSONStringFromDictionary(from: appInfos) ?? ""
            let callBackString = "postvesioncode(\(jsonString))"
            
            webView.evaluateJavaScript(callBackString) { result, error in
                print(result as Any)
                print(error as Any)
            }
        } else if message.name == "openPage"{
            print(message.body as Any)
            if let messageStr = message.body as? String {
                let messageDic = self.getDictionaryFromJSONString(jsonString: messageStr)
                let nextVC = ViewController()
                nextVC.hidenNaviBar = false
                nextVC.currentUrl = "\(messageDic["URL"] ?? "")"
                nextVC.topTile = "\(messageDic["name"] ?? "")"
                nextVC.naviBarFlag = "\(messageDic["theme"] ?? "")"
                nextVC.watermarkWord = self.watermarkWord
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        }
    }
    
    func getJSONStringFromDictionary(from object: Any) -> String? {
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            let objectString = String(data: objectData, encoding: .utf8)
            return objectString
        }
        return ""
    }
    
    func requestLatestVersion() {
        let urlString = App_MainUrl + DownloadUrl
        //获取本地版本号
        let infoDictionary = Bundle.main.infoDictionary
        let appVersion = infoDictionary!["CFBundleShortVersionString"] as! String
        AF.request(urlString, method: .post, parameters: ["packageVersion":appVersion, "packageType":"2"], encoding: JSONEncoding.default, requestModifier: { $0.timeoutInterval = 60 }).validate(contentType: ["application/json", "text/html"]).response(completionHandler: { response in
            switch response.result {
            case .success(response.data):
                let result = String(data: response.data ?? Data.init(), encoding: .utf8) ?? ""
                let resultDic = self.getDictionaryFromJSONString(jsonString: result)
                print(resultDic)
                let dataDic = resultDic["data"] as? NSDictionary ?? NSDictionary()
                let isUpdate = dataDic["isUpdate"] as? Bool ?? false
                let downloadUrl = "\(dataDic["packageDownloadUrl"] ?? "")"
                if isUpdate {
                    self.updateApp(downloadUrl: "itms-services://?action=download-manifest&url=" + downloadUrl)
                }
            default:
                let error = response.error
                print(error.debugDescription)
            }
        })
    }
    
    func updateApp(downloadUrl: String) {
        let alertCtrol = UIAlertController(title: "发现新版本，是否更新？", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default) { action in
            if let url = URL(string: downloadUrl) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertCtrol.addAction(okAction)
        alertCtrol.addAction(cancelAction)
        present(alertCtrol, animated: true, completion: nil)
    }
    
    // JSONString转换为字典
    func getDictionaryFromJSONString(jsonString:String) ->NSDictionary{
        let jsonData: Data = jsonString.data(using: .utf8)!
        let result = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        if let dict = result as? NSDictionary {
            return dict
        }
        return NSDictionary()
    }
    
    @objc func handleScreenOrientationChange(noti: NSNotification) {
        let orient = UIDevice.current.orientation;
        
        switch (orient) {
        case .portrait:
            print("竖直屏幕");
            statusHeight = statusBarHeight
            if !hidenNaviBar {
                statusHeight = statusBarHeight + 44
            }
            self.updateConstraints()
        case .landscapeLeft:
            print("手机左转");
            statusHeight = 0
            if !hidenNaviBar {
                statusHeight = 44
            }
            self.updateConstraints()
        case .landscapeRight:
            print("手机右转");
            statusHeight = 0
            if !hidenNaviBar {
                statusHeight = 44
            }
            self.updateConstraints()
        default:
            print("orient ==== ", orient);
        }
        
    }
    
    func updateConstraints() {
        if naviBarView != nil {
            naviBarView.mas_updateConstraints { (make) in
                make?.top.equalTo()(self.view.mas_top)
                make?.left.equalTo()(self.view.mas_left)
                make?.right.equalTo()(self.view.mas_right)
                make?.height.equalTo()(statusHeight)
            }
            
            titleLbl.mas_updateConstraints { make in
                make?.bottom.equalTo()(naviBarView.mas_bottom)?.setOffset(-7)
                make?.left.equalTo()(naviBarView.mas_left)?.setOffset(44)
                make?.right.equalTo()(naviBarView.mas_right)?.setOffset(-44)
                make?.height.equalTo()(30)
            }
            
            backBtn.mas_updateConstraints { make in
                make?.bottom.equalTo()(naviBarView.mas_bottom)
                make?.left.equalTo()(naviBarView.mas_left)
                make?.width.equalTo()(64)
                make?.height.equalTo()(44)
            }
        }
        webView.mas_updateConstraints { (make) in
            make?.top.equalTo()(self.view.mas_top)?.setOffset(statusHeight)
            make?.bottom.equalTo()(self.view.mas_bottom)
            make?.left.equalTo()(self.view.mas_left)
            make?.right.equalTo()(self.view.mas_right)
        }
        bgmView.mas_updateConstraints { (make) in
            make?.top.equalTo()(self.view.mas_top)
            make?.bottom.equalTo()(self.view.mas_bottom)
            make?.left.equalTo()(self.view.mas_left)
            make?.right.equalTo()(self.view.mas_right)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if watermarkWord != "" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let _img = self.createWatermarkFor(Text: self.watermarkWord, andFullSize:CGSize(width: self.view.bounds.width, height: self.view.bounds.height))
                self.bgmView.backgroundColor = UIColor(patternImage: _img)
                self.bgmView.isHidden = false
            }
        } else {
            bgmView.isHidden = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.topBack != nil {
                self.topBack.removeFromSuperlayer()
                self.topBack = nil
            }
            if !self.hidenNaviBar {
                let naviBarBackColors = ["0":"#66CCFF", "1":"#FF9AA6", "2":"#73CC87"]
                if naviBarBackColors.keys.contains(self.naviBarFlag) {
                    self.topBack = self.setGradualTopToBottomColor(view: self.naviBarView, fromColor: UIColor.hexStringToColor(hex: naviBarBackColors[self.naviBarFlag] ?? "", alpha: 1), toCololr: UIColor.hexStringToColor(hex: "#FFFFFF", alpha: 1))
                }
                if self.topBack != nil {
                    self.naviBarView.layer.insertSublayer(self.topBack, at: 0)
                }
            }
        }
    }
    
    //上下渐变
    func setGradualTopToBottomColor(view:UIView,fromColor:UIColor,toCololr:UIColor,loactions:[NSNumber]=[0,1]) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        //  创建渐变色数组，需要转换为CGColor颜色
        gradientLayer.colors = [fromColor.cgColor,toCololr.cgColor]
        //  设置渐变颜色方向，左上点为(0,0), 右下点为(1,1)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint =  CGPoint(x: 0, y: 1)
        //  设置颜色变化点，取值范围 0.0~1.0
        gradientLayer.locations = loactions
        return gradientLayer
    }
    
    /// 创建全铺图片水印
    /// - Parameters:
    ///   - strTxt: 水印文本
    ///   - fsize: 全铺的尺寸
    ///   - corners: 圆角信息(可选)
    ///   - r: 圆角值(可选)
    /// - Returns: UIImage
    func createWatermarkFor(Text strTxt:String,
                            andFullSize fsize:CGSize,
                            andCorners corners:UIRectCorner? = nil,
                            withRadius r:CGFloat? = nil) -> UIImage {
        
        //[S] 1、设置水印样式
        let paragraphStyle:NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = 1.0
        paragraphStyle.alignment = .center
        
        var _attr:[NSAttributedString.Key:Any] = [
            .font : UIFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor:UIColor.hexStringToColor(hex: "#000000", alpha: 0.1),
            .paragraphStyle: paragraphStyle,
            .kern:1.0,
        ]
        
        if #available(iOS 14.0, *) {
            _attr[.tracking] = 1.0
        }
        
        let attributedString:NSMutableAttributedString = NSMutableAttributedString.init(string: strTxt)
        let stringRange = NSMakeRange(0, attributedString.string.utf16.count)
        attributedString.addAttributes(_attr,range: stringRange)
        //[E]
        
        //[S] 2、建立水印图
        let _max_value = attributedString.size().width > attributedString.size().height ? attributedString.size().width : attributedString.size().height
        let _size = CGSize.init(width: _max_value + 100, height: _max_value + 100)
        
        //2.1、设置上下文
        if UIScreen.main.scale > 1.5 {
            UIGraphicsBeginImageContextWithOptions(_size,false,0)
        }
        else{
            UIGraphicsBeginImageContext(_size)
        }
        var context = UIGraphicsGetCurrentContext()
        
        //2.2、根据中心开启旋转上下文矩阵
        //将绘制原点（0，0）调整到源image的中心
        context?.concatenate(.init(translationX: _size.width * 0.8, y: _size.height * 0.4))
        
        //以绘制原点为中心旋转45°
        context?.concatenate(.init(rotationAngle: -0.25 * .pi))
        
        //将绘制原点恢复初始值，保证context中心点和image中心点处在一个点(当前context已经发生旋转，绘制出的任何layer都是倾斜的)
        context?.concatenate(.init(translationX: -_size.width * 0.8, y: -_size.height * 0.4))
        
        //2.3、添加水印文本
        attributedString.draw(in: .init(origin: .zero, size: _size))
        
        //2.4、从上下文中获取水印图
        let _waterImg = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage.init()
        //[E]
        
        //[S] 3、重设上下文，建立底图
        if UIScreen.main.scale > 1.5 {
            UIGraphicsBeginImageContextWithOptions(fsize,false,0)
        }
        else{
            UIGraphicsBeginImageContext(fsize)
        }
        context = UIGraphicsGetCurrentContext()
        
        //3.1圆角底图(可选)
        if corners != nil && r != nil && r?.isNaN == false && r?.isFinite != false {
            let rect:CGRect = .init(origin: .zero, size: fsize)
            let bezierPath:UIBezierPath = UIBezierPath.init(roundedRect: rect,
                                                            byRoundingCorners: corners!,
                                                            cornerRadii: CGSize(width: r!, height: r!))
            
            context?.addPath(bezierPath.cgPath)
        }
        
        //3.2 将水印图贴上去
        var _tempC = fsize.width / _waterImg.size.width
        var _maxColumn:Int = _tempC.isNaN || !_tempC.isFinite ? 1 : Int(_tempC)
        if fsize.width.truncatingRemainder(dividingBy: _waterImg.size.width) != 0 {
            _maxColumn += 1
        }
        
        _tempC = fsize.height / _waterImg.size.height
        var _maxRows:Int = _tempC.isNaN || !_tempC.isFinite ? 1 : Int(_tempC)
        if fsize.height.truncatingRemainder(dividingBy: _waterImg.size.height) != 0 {
            _maxRows += 1
        }
        
        for r in 0..<_maxRows {
            for c in 0..<_maxColumn {
                let _rect:CGRect = .init(origin: .init(x: CGFloat(c) * _waterImg.size.width,
                                                       y: CGFloat(r) * _waterImg.size.height),
                                         size: _waterImg.size)
                _waterImg.draw(in: _rect)
            }
        }
        
        //裁剪、透明
        context?.clip()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(.init(origin: .zero, size: fsize))
        
        //3.3 输出最终图形
        let _canvasImg = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage.init()
        //[E]
        
        //4、关闭图形上下文
        UIGraphicsEndImageContext()
        
        return _canvasImg
    }
}

