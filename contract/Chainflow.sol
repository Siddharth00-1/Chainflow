// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // State variables
    address public owner;
    uint256 public taskCounter;
    
    // Structs
    struct Task {
        uint256 id;
        string title;
        string description;
        address assignee;
        TaskStatus status;
        uint256 createdAt;
        uint256 completedAt;
    }
    
    enum TaskStatus {
        Created,
        InProgress,
        Completed,
        Cancelled
    }
    
    // Mappings and arrays
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userTasks;
    
    // Events
    event TaskCreated(uint256 indexed taskId, string title, address indexed assignee);
    event TaskStatusUpdated(uint256 indexed taskId, TaskStatus status);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId <= taskCounter, "Task does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        taskCounter = 0;
    }
    
    // Core Function 1: Create Task
    function createTask(
        string memory _title,
        string memory _description,
        address _assignee
    ) public onlyOwner returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_assignee != address(0), "Invalid assignee address");
        
        taskCounter++;
        
        tasks[taskCounter] = Task({
            id: taskCounter,
            title: _title,
            description: _description,
            assignee: _assignee,
            status: TaskStatus.Created,
            createdAt: block.timestamp,
            completedAt: 0
        });
        
        userTasks[_assignee].push(taskCounter);
        
        emit TaskCreated(taskCounter, _title, _assignee);
        return taskCounter;
    }
    
    // Core Function 2: Update Task Status
    function updateTaskStatus(uint256 _taskId, TaskStatus _status) 
        public 
        taskExists(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(
            msg.sender == task.assignee || msg.sender == owner,
            "Only assignee or owner can update status"
        );
        require(task.status != TaskStatus.Cancelled, "Cannot update cancelled task");
        
        task.status = _status;
        
        if (_status == TaskStatus.Completed) {
            task.completedAt = block.timestamp;
        }
        
        emit TaskStatusUpdated(_taskId, _status);
    }
    
    // Core Function 3: Assign Task to New User
    function reassignTask(uint256 _taskId, address _newAssignee) 
        public 
        onlyOwner 
        taskExists(_taskId) 
    {
        require(_newAssignee != address(0), "Invalid assignee address");
        require(tasks[_taskId].status != TaskStatus.Completed, "Cannot reassign completed task");
        
        Task storage task = tasks[_taskId];
        address oldAssignee = task.assignee;
        
        // Remove from old assignee's tasks
        uint256[] storage oldTasks = userTasks[oldAssignee];
        for (uint256 i = 0; i < oldTasks.length; i++) {
            if (oldTasks[i] == _taskId) {
                oldTasks[i] = oldTasks[oldTasks.length - 1];
                oldTasks.pop();
                break;
            }
        }
        
        // Add to new assignee's tasks
        task.assignee = _newAssignee;
        userTasks[_newAssignee].push(_taskId);
        
        emit TaskAssigned(_taskId, _newAssignee);
    }
    
    // View functions
    function getTask(uint256 _taskId) 
        public 
        view 
        taskExists(_taskId) 
        returns (Task memory) 
    {
        return tasks[_taskId];
    }
    
    function getUserTasks(address _user) 
        public 
        view 
        returns (uint256[] memory) 
    {
        return userTasks[_user];
    }
    
    function getTotalTasks() public view returns (uint256) {
        return taskCounter;
    }
}
