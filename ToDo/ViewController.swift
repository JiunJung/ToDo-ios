//
//  ViewController.swift
//  ToDo
//
//  Created by 정지운 on 10/2/24.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    //UIApplication.shared.delegate를 통해 AppDelegate.swift에 접근하여 persistenetContainer라는 Property 가져옴
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var tableView: UITableView!
    var todos:[Todo] = []
    //var todosTest: [String] = []
    var isEditingTableCell = false // 테이블 셀(텍스트 필드)을 수정하고 있는지 아닌지를 판단하는 변수
    var temporaryArray:[String?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        fetchTodos()
        
        // 화면 전체에 터치 제스처 추가 (#selector는 objc 타입의 함수를 부르는데 사용)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        for todo in todos{
            print("Items in todos : \(todo.task!)")
        }
        
    }
    
    //swift함수가 objc런타임환경에서도 돌아가게 하기위하여 @objc 붙임.
    @objc func handleScreenTap(_ gesture: UITapGestureRecognizer) {
        if isEditingTableCell == false {
            isEditingTableCell = true
            
            addTodoTask(taskName: "", taskDate: Date())
        
            let newIndexPath = IndexPath(row: todos.count - 1, section: 0)
            
            //셀 추가
            tableView.beginUpdates() // 이렇게 하면 tableView 델레게이크 메서드가 실행되고 todosTest.count가 있으므로 셀이 보인다.
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            tableView.endUpdates()
            
            // 새로 추가된 셀에 포커스 맞추기
            if let cell = tableView.cellForRow(at: newIndexPath) {
                print("done!")
                let textField = UITextField(frame: cell.contentView.bounds)
                textField.delegate = self
                textField.becomeFirstResponder()  // 텍스트 필드에 포커스 맞추기 (키보드 띄우기)
                cell.contentView.addSubview(textField)
                
                
            }
        }
        else if isEditingTableCell == true {
            // 기존에 있던 셀을 수정할 때, 수정을 마치려고 화면을 탭한 경우에 이 조건문 발동.
            isEditingTableCell = false
            view.endEditing(true)
        }

    }
    
    // MARK: - UITextFieldDelegate 메서드
    @objc func textFieldDidEndEditing(_ textField: UITextField) {
        // 텍스트 필드가 포커스를 잃었을 때 호출됨(return을 눌렀거나, 다른 곳을 터치했을 경우)
        guard let cell = textField.superview?.superview as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        
        let taskText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if taskText.isEmpty {
            // 텍스트가 빈 문자열인 경우: 해당 셀을 삭제
            if let cell = tableView.cellForRow(at: indexPath) {
                for subview in cell.contentView.subviews {
                    if let textField = subview as? UITextField {
                        textField.removeFromSuperview()  // 텍스트 필드 제거
                    }
                }
            }
            
            let todoToDelete = todos[indexPath.row]
            deleteTodoTask(todo: todoToDelete)
            todos.remove(at: indexPath.row) //배열에서 데이터 삭제
            
            // 테이블 뷰에서 셀 삭제
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
        } else {
            // 텍스트가 있는 경우: 배열에 저장. (만약 새로운 셀이라면 데이터 Create)
            if indexPath.row >= todos.count {
                addTodoTask(taskName: taskText, taskDate: Date())
            }else{
                updateTodoTask(todo: todos[indexPath.row], newTaskName: taskText, newTaskDate: Date())
            }
        }
        isEditingTableCell = false
        print("todos : \(todos)")
    }
    
    //앱이 백그라운드로 전활될 때 실행되는 함수.
    @objc func appDidEnterBackground(){
        //task 가 빈 문자열일 경우 Todo Core Data 및 todos 배열에서 삭제해야 함. -> textFieldDidEndEditing 호출
        view.endEditing(true)
        
        //백그라운드에 있다가 다시 돌아올 수도 있으므로, 테이블 뷰를 reload해주자.
        tableView.reloadData()
        
    }
    
    
    // UITextField가 편집을 시작할 때 호출되는 메서드
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // 셀의 텍스트 필드를 눌러서 편집이 시작되면, isEditingTableCell을 true로 설정
        isEditingTableCell = true
    }
    
    // text 필드에서 키보드에서 return을 눌렀을 때 -> 여기서도 위와 똑같이 적용될 수 있도록 해야 함.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // 키보드를 내리고, 텍스트 필드의 포커스를 해제.
        isEditingTableCell = false
        view.endEditing(true)
        
        return true
    }
    
    //-----------------------------------------------------------Core Data CRUD Functions-------------------------------------------------------------//
    
    //data Create(데이터 추가)
    func addTodoTask(taskName: String, taskDate: Date) {
        let newTodo = Todo(context: self.context)
        newTodo.task = taskName
        newTodo.date = taskDate
        todos.append(newTodo)
        // AppDelegate의 saveContext() 함수 호출로 저장
        do{
            try self.context.save()
        }catch{
            print("Failed to add tasks: \(error.localizedDescription)")
        }
    }
    
    // data Read(Core Data에서 데이터를 불러오는 함수)
    func fetchTodos() {
        let fetchRequest: NSFetchRequest<Todo> = Todo.fetchRequest()

        do {
            todos = try self.context.fetch(fetchRequest) //앱을 켜면 로컬에 있는 데이터를 todos에 집어넣음.
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to fetch tasks: \(error.localizedDescription)")
        }
    }
    
    //data Update(데이터 수정)
    func updateTodoTask(todo: Todo, newTaskName: String, newTaskDate: Date) {
        todo.task = newTaskName
        todo.date = newTaskDate
        // 변경 사항 저장
        do{
            try self.context.save()
        }catch{
            print("Failed to update tasks: \(error.localizedDescription)")
        }
    }
    
    //data Delete(데이터 삭제)
    func deleteTodoTask(todo: Todo) {
        self.context.delete(todo)
        // 삭제 후 변경 사항 저장
        do{
            try self.context.save()
        }catch{
            print("Failed to delete tasks: \(error.localizedDescription)")
        }
    }

    //--------------------------------------------------------------------Table View Delegate Functions-------------------------------------------------------------------------//
    
    //Delegate Functions from UITableViewDelegate and UITableViewDataSouce
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if todos.isEmpty {
            
            // 데이터가 없을 때 "No To-do for the day" 레이블을 테이블 뷰 배경에 추가
            let noDataLabel: UILabel = {
                let label = UILabel()
                label.text = "No To-do for the day"
                label.textColor = .gray
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 20)
                return label
            }()
            
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none  // 구분선 제거
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine  // 구분선 표시
            return todos.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath)
        
        let todo = todos[indexPath.row]
        
        //아래의 코드 한 줄이 셀 순서가 뒤바뀌는 것을 막는다. 셀 재사용 과정에서 이전에 삭제되지 않은 서브뷰인 텍스트뷰가 중복으로 떠서 뒤바뀌는 것이다.
        cell.contentView.subviews.forEach { $0.removeFromSuperview() } //중복된 서브뷰를 방지하기 위해, 모든 서브뷰를 제거.
        
        let textField = UITextField(frame: cell.contentView.bounds)
        textField.text = todo.task
        textField.delegate = self
        
        // 중복 추가 방지
        if cell.contentView.subviews.isEmpty {
            cell.contentView.addSubview(textField)
        }

        return cell
    }

    // 테이블에서 데이터 삭제
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let todoToDelete = todos[indexPath.row]
            deleteTodoTask(todo: todoToDelete)
            todos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    
    
    
}

