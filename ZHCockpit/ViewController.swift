//
//  ViewController.swift
//  ScreenShield
//
//  Created by apple on 2023/11/20.
//

import UIKit
import WebKit
import Alamofire
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var bgmView: UIImageView!
    var webView: WKWebView!
    var myBtn: UIButton!
    var statusHeight: CGFloat = 0
    
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    override func loadView() {
        super.loadView()
        view = ScreenShieldView.create(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        webView = WKWebView.init()
        if let h5Url = URL(string: H5_App_MainUrl) {
            webView.load(URLRequest(url: h5Url))
        }
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(webView)
        webView.allowsBackForwardNavigationGestures = true
        
        bgmView = UIImageView()
        bgmView.alpha = 0.4
        bgmView.backgroundColor = .gray
        view.addSubview(bgmView)
        
        myBtn = UIButton(type: .system)
        myBtn.backgroundColor = .lightGray
        myBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        myBtn.setTitleColor(.green, for: .normal)
        myBtn.setTitle("获取图片", for: .normal)
        myBtn.addTarget(self, action: #selector(myBtnClick(sender:)), for: .touchUpInside)
        view.addSubview(myBtn)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenOrientationChange(noti:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.shouldRotate = true
        
        self.getRotationChartRequst(userCode: "1010000000072")
        // Do any additional setup after loading the view.
    }
    
    @objc func myBtnClick(sender: UIButton) {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        if authStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.openPhotoLibrary()
                }
            }
        } else if authStatus == .authorized {
            self.openPhotoLibrary()
        }
    }
    
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.modalPresentationStyle = .fullScreen
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let originImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.bgmView.image = originImage
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func getRotationChartRequst(userCode:String) {
        let urlString = "https://www.baidu.com/"
        AF.request(urlString, method: .post, parameters: [:], encoding: JSONEncoding.default, requestModifier: { $0.timeoutInterval = 60 }).validate(contentType: ["application/json", "text/html"]).response(completionHandler: { response in
            switch response.result {
            case .success(response.data):
                let result = String(data: response.data ?? Data.init(), encoding: .utf8) ?? ""
                let resultDic = self.getDictionaryFromJSONString(jsonString: result)
                print(resultDic)
            default:
                let error = response.error
                print(error.debugDescription)
            }
        })
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
        let appModel = UIDevice.current.model
        
        switch (orient) {
        case .portrait:
            print("竖直屏幕");
            statusHeight = statusBarHeight
            self.updateConstraints()
        case .landscapeLeft:
            print("手机左转");
            statusHeight = 0
            if appModel == "iPad" {
                statusHeight = statusBarHeight
            }
            self.updateConstraints()
        case .landscapeRight:
            print("手机右转");
            statusHeight = 0
            if appModel == "iPad" {
                statusHeight = statusBarHeight
            }
            self.updateConstraints()
        default:
            print("orient ==== ", orient);
        }
        
    }
    
    func updateConstraints() {
        webView.mas_updateConstraints { (make) in
            make?.top.equalTo()(self.view.mas_top)?.setOffset(statusHeight)
            make?.bottom.equalTo()(self.view.mas_bottom)
            make?.left.equalTo()(self.view.mas_left)
            make?.right.equalTo()(self.view.mas_right)
        }
        bgmView.mas_updateConstraints { (make) in
            make?.top.equalTo()(self.view.mas_top)?.setOffset(statusHeight)
            make?.bottom.equalTo()(self.view.mas_bottom)
            make?.left.equalTo()(self.view.mas_left)
            make?.right.equalTo()(self.view.mas_right)
        }
        myBtn.mas_updateConstraints { (make) in
            make?.top.equalTo()(self.view.mas_top)?.setOffset(statusHeight + 30)
            make?.left.equalTo()(self.view.mas_left)?.setOffset(40)
            make?.size.mas_equalTo()(CGSize(width: 100, height: 30))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let _img = createWatermarkFor(Text:"    水印文本1、水印文本2", andFullSize:CGSize(width: view.bounds.width, height: view.bounds.height))
        bgmView.backgroundColor = UIColor(patternImage: _img)
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
            .foregroundColor:UIColor.hexStringToColor(hex: "#000000", alpha: 0.4),
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

