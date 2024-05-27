//
//  PhotoViewController.swift
//  CameraApp
//
//  Created by Labe on 2024/5/13.
//

import UIKit
import CoreImage.CIFilterBuiltins


class PhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cutView: UIView!
    @IBOutlet weak var changeImageSizeSgmController: UISegmentedControl!
    @IBOutlet weak var filterScrollView: UIScrollView!
    @IBOutlet var colorControlsView: UIView!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var contrastSlider: UISlider!
    @IBOutlet weak var saturationSlider: UISlider!
    
    @IBOutlet var buttons: [UIButton]! //設定元件用
    
    var isTransform:CGFloat = 1 //鏡像
    let oneDegree = CGFloat.pi / 180 //90度轉向
    var turnRightCount:CGFloat = 0 //轉向次數
    var originalImage:UIImage? //原始相片，可以用作無濾鏡、重置等用途
    var filteredImage:UIImage? //用來存取套過濾鏡的相片
    let context = CIContext() //一個圖像處理的環境，負責管理和執行圖像處理操作。
    
    //判斷是否已有選擇相片，如果未選擇相片就提醒始歲者先選取相片
    func isHaveImage() -> Bool {
        if originalImage == nil {
            let alerController = UIAlertController(title: "請先選取相片", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "好的", style: .cancel)
            alerController.addAction(okAction)
            present(alerController, animated: true)
            return false
        }
        return true
    }
    
    //隱藏調整圖片的工具
    func hiddenTools() {
        cutView.isHidden = true
        filterScrollView.isHidden = true
        colorControlsView.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hiddenTools()
        //不知為何設定不出來的字體😵‍💫
        let font = UIFont(name: "NaikaiFont-Regular-Lite", size: 15)
        for i in 0...buttons.count-1 {
            buttons[i].titleLabel?.font = font
        }
    }
    
    //相機功能
    @IBAction func camera(_ sender: Any) {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = self
        present(controller, animated: true)
    }
    
    //選擇相片：設定代理人(delegate)
    @IBAction func selectImage(_ sender: UIButton) {
        let controller = UIImagePickerController()
        controller.sourceType = .photoLibrary
        controller.delegate = self
        present(controller, animated: true)
    }
    
    //調整固定大小
    @IBAction func changeImageSize(_ sender: UISegmentedControl) {
        let width = 393
        var height = 0
        if sender.selectedSegmentIndex == 0 {
            height = width
        } else if sender.selectedSegmentIndex == 1 {
            height = width / 3 * 4
        } else {
            height = width / 16 * 9
        }
        //將計算好的長寬帶入圖片
        imageView.frame.size = CGSize(width: width, height: height)
        //讓圖片維持在一定位置，不會因為改變大小亂跑
        imageView.center = CGPoint(x: 195, y: 365)
    }
    
    //鏡像
    @IBAction func mirrorImage(_ sender: Any) {
        isTransform *= -1
        setTransform()
    }
    
    //90度向右旋轉
    @IBAction func turnRightImage(_ sender: Any) {
        turnRightCount += 1
        if turnRightCount == 4 {
            turnRightCount = 0
        }
        setTransform()
    }
    
    //另外寫function來做相片旋轉或鏡像的設定，如果分開設定的話，在旋轉時鏡像效果會被取消，反之亦然
    func setTransform() {
        imageView.transform = CGAffineTransform(scaleX: isTransform, y: 1).rotated(by: oneDegree * 90 * turnRightCount * isTransform)
    }
    
    //顯示點選的工具列（裁剪、濾鏡、色彩調整）
    @IBAction func showAdjustTool(_ sender: UIButton) {
        if isHaveImage() {
            hiddenTools()
            let option = AdjustTool(rawValue: sender.tag)
            switch option {
            case .cut:
                cutView.isHidden = false
            case .filter:
                filterScrollView.isHidden = false
            case .colorControls:
                colorControlsView.isHidden = false
            default:
                break
            }
        }
    }
    
    //套用濾鏡
    @IBAction func filter(_ sender: UIButton) {
        guard let originalImage = originalImage,
              let option = Filter(rawValue: sender.tag) else {return} //把濾鏡enum設為選項清單，配合button的tag，用於switch選項使用
        let ciImage = CIImage(image: originalImage)
        var filter:CIFilter?
        
        
        //選擇濾鏡，並設定濾鏡的數值（有些濾鏡可以依照喜好自訂數值）
        switch option {
        case .original:
            // 先把原始圖片轉成CIImage
            let originalCIImge = CIImage(image: originalImage)
            // 再把原始方向設定進去，生成轉向設定完成的rotateCIImage
            if let rotateCIImage = originalCIImge?.oriented(CGImagePropertyOrientation(originalImage.imageOrientation)) {
                // 再將方向設定過後的rotetaCIImage轉成CGImage，再轉回UIImage後設定給imageView。如果少了轉CGImage這一步，直接轉回UIImage，圖片之後有再次轉型時就會有問題，例如這邊遇到的問題是：套濾鏡時選回原圖選項，再次調整colorControls時，在把圖片轉成CIImage時就會變成nil，倒置沒有圖片可以被套上colorControls，imageView在使用者看來就會沒有變化
                if let cgImage = context.createCGImage(rotateCIImage, from: rotateCIImage.extent) {
                    imageView.image = UIImage(cgImage: cgImage)
                }
            }
        case .vibrance:
            filter = CIFilter.vibrance()
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(0.5, forKey: kCIInputAmountKey)
        case .photoEffectChrome:
            filter = CIFilter.photoEffectChrome()
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
        case .highlightShadowAdjust:
            filter = CIFilter.highlightShadowAdjust()
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(2, forKey: "inputShadowAmount")
        case .gammaAdjust:
            filter = CIFilter.gammaAdjust()
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(2, forKey: "inputPower")
        case .dotScreen:
            filter = CIFilter.dotScreen()
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(0, forKey: kCIInputAngleKey)
            filter?.setValue(CIVector(x: 195, y: 195), forKey: kCIInputCenterKey)
            filter?.setValue(10, forKey: kCIInputWidthKey)
            filter?.setValue(0.7, forKey: kCIInputSharpnessKey)
        }
        
        //將套上濾鏡的相片輸出、轉型，處理套上濾鏡會轉向的問題後把相片設定給imageView，最後呼叫設定相片翻轉的function，不然翻轉效果會被覆蓋掉
        if let outputCIImage = filter?.outputImage {
            let rotateCIImage = outputCIImage.oriented(CGImagePropertyOrientation(originalImage.imageOrientation))
            if let cgImage = context.createCGImage(rotateCIImage, from: rotateCIImage.extent) {
                imageView.image = UIImage(cgImage: cgImage)
            }
            setTransform()
        }
        //把套了濾鏡的相片存起來
        //因為這邊使用的是原始相片originalImage來套濾鏡，亮度、對比度、飽和度（colorControls）是另外由「調整」按鈕來做客製化，所以有另外存取colorControls的數值，這邊再套上一次，避免因為選擇濾鏡而讓相片調整過colorControls的效果消失
        filteredImage = imageView.image
        setColorControlsImage()
    }

    
    
    //調整亮度、對比度、飽和度：CIFilter.colorControls()
    
    //存取數值
    private var mBrightnessValue: Float = 0
    private var mContrastValue: Float = 1
    private var mSaturationValue: Float = 1
    
    //存取slider數值，並把討好效果的相片設定給imageView
    @IBAction func adjustColorControls(_ sender: UISlider) {
        //取得濾鏡-ColorControls的數值，呼叫setColorControlsImage()來套入濾鏡
        switch ColorControls(rawValue: sender.tag) {
        case .brightness:
            mBrightnessValue = sender.value
        case .contrast:
            mContrastValue = sender.value
        case .saturation:
            mSaturationValue = sender.value
        default:
            break
        }
        setColorControlsImage()
    }
    
    //套入colorControls的濾鏡(配合silder數值)
    func setColorControlsImage() {
        if let filteredImage {
            let filter = CIFilter.colorControls()
            let ciImage = CIImage(image: filteredImage)
            
            filter.inputImage = ciImage
            filter.brightness = mBrightnessValue
            filter.contrast = mContrastValue
            filter.saturation = mSaturationValue
            
            if let outputCIImage = filter.outputImage {
                let rotateCIImage = outputCIImage.oriented(CGImagePropertyOrientation(filteredImage.imageOrientation))
                if let cgImage = context.createCGImage(rotateCIImage, from: rotateCIImage.extent) {
                    let currentFilteredImage = UIImage(cgImage: cgImage)
                    imageView.image = currentFilteredImage
                }
            }
        }
    }
    
    //重置
    @IBAction func resetImage(_ sender: Any) {
        if isHaveImage() {
            guard let originalImage = originalImage else {return}
            imageView.image = originalImage
            imageView.frame.size = CGSize(width: 390, height: 390)
            imageView.center = CGPoint(x: 195, y: 365)
            isTransform = 1
            turnRightCount = 0
            setTransform()
            changeImageSizeSgmController.selectedSegmentIndex = 0
            brightnessSlider.value = 0
            contrastSlider.value = 1
            saturationSlider.value = 1
            hiddenTools()
        }
    }
    
    //保存相片
    @IBAction func saveImage(_ sender: Any) {
        if isHaveImage() {
            if let image = imageView.image {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
            
            let alerController = UIAlertController(title: "已存取相片", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel)
            alerController.addAction(okAction)
            present(alerController, animated: true)
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}



//遵循UIImagePickerControllerDelegate、UINavigationControllerDelegate，將選取的的相片存入originalImage跟filteredImage，並設定在選完相片後關掉UIImagePickerController
extension PhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        originalImage = imageView.image
        filteredImage = imageView.image
        dismiss(animated: true)
    }
}

//解決套濾鏡相片會旋轉的問題（可參考下列文章）
//拓展CGImagePropertyOrientation的功能，以便根據 UIImage.Orientation 值進行初始化。CGImagePropertyOrientation 和 UIImage.Orientation 都表示圖像的方向，但用於不同的框架：前者用於 Core Graphics，後者用於 UIKit。這個擴展使得將一個 UIKit 中的 UIImage.Orientation 轉換為 Core Graphics 中的 CGImagePropertyOrientation 更加方便。
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}
