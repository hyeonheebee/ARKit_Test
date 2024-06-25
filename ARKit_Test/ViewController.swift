//
//  ViewController.swift

//

import UIKit
import SceneKit
import ARKit
import SceneKit.ModelIO
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate  {
    
    // ARKit과 SceneKit을 결합한 뷰로, ARKit을 사용하여 실제 환경을 추적하고 SceneKit을 사용하여 3D 콘텐츠를 렌더링하는 역할을 합니다. 스토리보드에 ARSCNView 타입으로 깔려있고 sceneView 변수로 이름지었습니다
    @IBOutlet weak var sceneView: ARSCNView!
    
 
    // 제스쳐용 플래그 추가
    
    // 선택된 노드를 확인하는 변수
    var selectedNode: SCNNode?
    
    // 노드의 기존 위치를 저장하는 변수(펜-드래그- 제스쳐를 이용하여 객체를 이동시킬때 기존위치를 저장합니다)
    var originalNodePosition: SCNVector3?
    
    // 노드의 기존 스케일을 저장하는 변수(핀치 제스쳐를 이용하여 객체를 늘이고 줄일때 사용합니다)
    var originalScale: SCNVector3?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //뷰컨트롤러가 뷰에서 일어나는 행위를 반응할 수 있게 델리게이트패턴(대리자 선언)을 사용합니다
        sceneView.delegate = self
        
        // SCNScene 인스턴스를 생성하여 scene 변수에 담습니다
        let scene = SCNScene()
        
        // sceneView(여기서는 ARSCNView 타입)의 scene 속성에 위에서 만든 SCNScene 인스턴스를 담습니다
        sceneView.scene = scene
        // 여기까지가 SceneKit 와 관련된 설명입니다
        
        // 제스처 인식기 추가(제스쳐를 화면에서 인식할 수 있게 합니다)
        addGestureRecognizers()
        
        // 모델이름을 넣어 usdz 파일의 모델을 업로드 할 수 있습니다. 여기서는 art.scnassets폴더에 있는 usdz 샘플파일인 Candle_Animated를 넣었습니다.
        loadUSDZModel(model: "Candle_Animated")
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ARSession 설정 configuration
        let configuration = ARWorldTrackingConfiguration()
        // ARWorldTrackingConfiguration은 사람을 인식해서 사람 사이의 거리를 계산하여 객체를 위치시키는 기능으로 해당 설정은 configuration 변수에 담습니다
        //  personSegmentation 프레임 시맨틱을 사용하면 객체 앞에 있는 사람은 앞쪽에 표시, 객체 뒤에있는 사람은 객체에 가리게 되어 우너금감이 생갑니다
        // 객체를 강조하기 위해 해당 코드 생략도 가능합니다(객체가 최상단에 오는것처럼 보입니다)
        configuration.frameSemantics.insert(.personSegmentation)
        configuration.detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources", bundle: nil) ?? []
         sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])

        // 세션구동 run 메서드(앞서 설정한 configuration 설정으로 구동합니다)
        // sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 세션 중지 (뷰가 표현되지 않을때 불필요한 리소스 활용을 줄입니다)
        sceneView.session.pause()
    }
    
    
    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    // 제스쳐관련 인식기 함수입니다. 해당 함수를 실행하면 다양한 제스쳐에 대해 sceneView가 인식할 수 있게 됩니다.
    func addGestureRecognizers() {
        
        // 탭 제스처 인식기 설정 후 뷰에 할당
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
        tapGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        
        // 팬 제스처 인식기 설정 후 뷰에 할당
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
        
        
        // 핀치(엄지-검지 사용) 제스처 인식기 설정 후 뷰에 할당
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        
        // 롱프레스(꾹 누르기) 제스처 인식기 설정 후 뷰에 할당
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        // 최소  2초동안은 프레싱되어야 제스쳐를 인식합니다
        longPressGestureRecognizer.minimumPressDuration = 2
        // 2초 안에 들어오는 제스쳐는 삭제합니다(버리기)
        longPressGestureRecognizer.delaysTouchesBegan = true
        sceneView.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    
    
    // 샘플 애니메이션 (y축 회전 애니메이션)
    func addRotateAnimation(node: SCNNode) {
        // y축으로 0,8만큼 5초동안 돕니다
        let rotateOneTime = SCNAction.rotateBy(x: 0, y: 0.8, z: 0, duration: 5)
        // rotateOneTime 동작을 계속 반복합니다
        let actionForever = SCNAction.repeatForever(rotateOneTime)
        // 액션을 노드가 실행합니다(객체가 움직입니다)
        node.runAction(actionForever)
    }
    
    // 샘플 애니메이션(위 아래 움직임 반복)
    func addMoveUpDownAnimation(node: SCNNode) {
        let moveUp = SCNAction.moveBy(x: 0, y: 3, z: 0, duration: 2.5)
        let moveDown = SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 2.5)
        let moveSequence = SCNAction.sequence([moveUp, moveDown])
        let actionRepeat = SCNAction.repeatForever(moveSequence)
        node.runAction(actionRepeat)
    }
    
    
    // usdz파일을 활용해 증강현실 화면에 객체를 업로드합니다
    func loadUSDZModel(model modelName: String) {
        guard let url = Bundle.main.url(forResource: "art.scnassets/\(modelName)", withExtension: "usdz"),
              let node = SCNReferenceNode(url: url) else {
            print("USDZ 파일을 찾을 수 없습니다: \(modelName)")
            return
        }
        
      
        // 노드를 올립니다
        node.load()
        // 모델의 특성에 따라 위치 조정, 스케일링 등을 초기에 할 수 있습니다. 여기서는 z축으로 -30만큼 보내게 했습니다(뒤로보냄)
        node.position = SCNVector3(x: 10, y: -10, z: -20)
        // 원하는 스케일로 조정
        node.scale = SCNVector3(x: 0.04, y: 0.04, z: 0.04)
        // 씬의 루트노드에 자식노드로 우리가 불러온 객체노드를 추가합니다
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    
    
    // 탭 제스쳐를 인식하면 하게 할 행동들에 대한 함수입니다. 원하는 액션을 넣습니다. 현재는 촛불의 불꽃부분의 노드를 찾아서 눌림여부에 따라 토글형식으로 불꽃노드가 on/off(isHidden = true / isHidden = false) 됩니다
    @objc func handleTap(gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        if let hitResult = hitResults.first {
            selectedNode = hitResult.node
            while let parent = selectedNode?.parent, parent !== sceneView.scene.rootNode {
                selectedNode = parent
            }
            originalNodePosition = selectedNode?.position
            originalScale = selectedNode?.scale
            if let selectedNode = selectedNode {
                let candleNodeName = "Cone_3"
                if let candleNode = selectedNode.childNode(withName: candleNodeName, recursively: true) {
                    if let candleInnerNode = candleNode.childNode(withName: "Object_4", recursively: true) {
                        if candleInnerNode.isHidden {
                            candleInnerNode.isHidden = false
                        }
                        else {
                            candleInnerNode.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    
    // 드래그 제스쳐(pan 제스쳐)를 인식한 후 하게 될 행동들에 대한 함수입니다. 현재는 객체의 위치를 기억하고, pan (드래그) 가 되었던 정도에따라 계산하여 객체의 위치를 변경합니다(손 제스쳐에 따라 객체가 이동됩니다)
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        //  gesture.location(in: sceneView)는 제스처 이벤트가 발생한 터치 위치를 sceneView 좌표계에서 반환
        let location = gesture.location(in: sceneView)
        switch gesture.state {
        case .began:
            // 제스처의 상태를 확인합니다. 여기서는 제스처가 시작될 때(.began)만 코드를 실행합니다.
            let hitResults = sceneView.hitTest(location, options: nil)
            // sceneView.hitTest(location, options: nil)는 터치 위치(location)에서 히트 테스트를 수행하여 해당 위치에 있는 노드들을 반환(히트 테스트는 터치된 지점에 어떤 노드들이 있는지 확인하는 과정임)
            if let hitResult = hitResults.first {
                selectedNode = hitResult.node
                //히트 테스트 결과에서 첫 번째 노드를 selectedNode로 선택합니다. hitResults.first는 히트된 노드들 중 첫 번째 노드를 반환합니다.
                while let parent = selectedNode?.parent, parent !== sceneView.scene.rootNode {
                    selectedNode = parent
                }
                /*
                 - 선택된 노드의 최상위 부모 노드를 찾기 위해 `while` 루프를 사용합니다.
                 - `selectedNode?.parent`가 `nil`이 아니고, `selectedNode`의 부모가 `sceneView.scene.rootNode`가 아닐 때까지 루프를 계속 실행합니다.
                 - `selectedNode`를 계속 부모 노드로 갱신하여 최상위 노드에 도달할 때까지 반복합니다.
                 */
                originalNodePosition = selectedNode?.position
            }
            
        case .changed:
            if let selectedNode = selectedNode, let originalNodePosition = originalNodePosition  {
                // transition은 제스처 인식기에서 현재 팬 동작의 이동 거리를 가져옵니다. 이 거리는 사용자가 화면에서 손가락을 얼마나 이동했는지를 나타냅니다.
                let translation = gesture.translation(in: sceneView)
                let newPosition = SCNVector3(
                    x: originalNodePosition.x + Float(translation.x * 0.05),
                    y: originalNodePosition.y + Float(translation.y * -0.05),
                    z: originalNodePosition.z + Float(translation.y * -0.05)
                )
                /*
                 - `translation` 값을 이용하여 `newPosition`을 계산합니다.
                 - `originalNodePosition.x`에 `translation.x`을 더하여 노드의 새로운 x 위치를 계산합니다. `translation.x`에 0.001을 곱한 것은 화면상의 이동 거리를 3D 공간상의 이동 거리로 변환하기 위함입니다.
                 - `originalNodePosition.y`는 그대로 유지됩니다. 이는 노드의 높이(y 축)를 변경하지 않음을 의미합니다.
                 - `originalNodePosition.z`에 `translation.y`을 더하여 노드의 새로운 z 위치를 계산합니다. 마찬가지로 `translation.y`에 0.001을 곱한 것은 화면상의 이동 거리를 3D 공간상의 이동 거리로 변환하기 위함입니다.
                 */
                selectedNode.position = newPosition
                // addAnimation(node: selectedNode)
                // addMoveUpDownAnimation(node: selectedNode)
            }
            
        case .ended, .cancelled:
            selectedNode = nil
            originalNodePosition = nil
        default:
            break
        }
    }
    
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let location = gesture.location(in: (gesture.view as! ARSCNView))
        switch gesture.state {
        case .began:
            //  let hitResults = sceneView.hitTest(location, options: nil)
            let hitTest = (gesture.view as! ARSCNView).hitTest(location)
            if let hitTest = hitTest.first {
                // 최상위 노드로 이동
                selectedNode = hitTest.node
                while let parent = selectedNode?.parent, parent !== sceneView.scene.rootNode {
                    selectedNode = parent
                }
                originalNodePosition = selectedNode?.position
            }
        case .changed:
            if let selectedNode = selectedNode, let originalScale = originalScale {
                let scale = Float(gesture.scale)
                selectedNode.scale = SCNVector3(x: originalScale.x * scale, y: originalScale.y * scale, z: originalScale.z * scale)
            }
        case .ended, .cancelled:
            if let selectedNode = selectedNode {
                originalScale = selectedNode.scale
            }
        default:
            break
        }
    }
    
    
    // 꾹 눌렸을때(롱프레스 제스쳐)의 행동들에 대한 함수입니다. 현재는 불꽃노드를 찾아서 MoveUpDownAnimation(샘플애니메이션으로 만들어놓은)을 수행합니다.
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        switch gesture.state {
        case .began:
            let hitResults = sceneView.hitTest(location, options: nil)
            if let hitResult = hitResults.first {
                selectedNode = hitResult.node
                while let parent = selectedNode?.parent, parent !== sceneView.scene.rootNode {
                    selectedNode = parent
                }
                originalNodePosition = selectedNode?.position
                originalScale = selectedNode?.scale
                if let selectedNode = selectedNode {
                    let candleNodeName = "Cone_3"
                    if let candleNode = selectedNode.childNode(withName: candleNodeName, recursively: true) {
                        if let candleInnerNode = candleNode.childNode(withName: "Object_4", recursively: true) {
                            addMoveUpDownAnimation(node: candleInnerNode)
                        }
                    }
                }
            }
        case .ended, .cancelled:
            let hitResults = sceneView.hitTest(location, options: nil)
            if let hitResult = hitResults.first {
                selectedNode = hitResult.node
                while let parent = selectedNode?.parent, parent !== sceneView.scene.rootNode {
                    selectedNode = parent
                }
                originalNodePosition = selectedNode?.position
                originalScale = selectedNode?.scale
                if let selectedNode = selectedNode {
                    let candleNodeName = "Cone_3"
                    if let candleNode = selectedNode.childNode(withName: candleNodeName, recursively: true) {
                        if let candleInnerNode = candleNode.childNode(withName: "Object_4", recursively: true) {
                            candleInnerNode.removeAllActions()
                        }
                    }
                }
            }
            selectedNode = nil
            originalNodePosition = nil
        default:
            break
        }
    }
}
