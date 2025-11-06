//
//  TasksView.swift
//  FocusFlow
//
//  任务视图
//

    import SwiftUI
    import SwiftData

    struct TasksView: View {
        @Environment(\.modelContext) private var modelContext
        @EnvironmentObject var focusViewModel: FocusViewModel
        @Query private var tasks: [Task]
        @StateObject private var viewModel = TasksViewModel()
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    // 筛选和排序栏
                    filterAndSortBar
                    
                    // 任务视图（根据模式切换）
                    if viewModel.filteredTasks.isEmpty {
                        emptyState
                    } else {
                        switch viewModel.viewMode {
                        case .list:
                            taskList
                        case .kanban:
                            kanbanView
                        case .calendar:
                            calendarView
                        }
                    }
                }
                .navigationTitle("任务")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 15) {
                            // 视图切换
                            Menu {
                                ForEach(TaskViewMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        viewModel.viewMode = mode
                                    }) {
                                        HStack {
                                            Text(mode.rawValue)
                                            if viewModel.viewMode == mode {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: viewModel.viewMode == .list ? "list.bullet" :
                                        viewModel.viewMode == .kanban ? "square.grid.2x2" : "calendar")
                            }
                            
                            // 新建任务
                            Button(action: {
                                viewModel.editingTask = nil
                                viewModel.showTaskForm = true
                            }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
                .sheet(isPresented: $viewModel.showTaskForm) {
                    TaskFormView(task: viewModel.editingTask, viewModel: viewModel)
                }
                .task {
                    // 确保在视图加载时立即更新任务
                    viewModel.updateTasks(tasks)
                }
                .onAppear {
                    // 在视图出现时也更新一次，确保数据同步
                    viewModel.updateTasks(tasks)
                }
                .onChange(of: tasks) { _, _ in
                    viewModel.updateTasks(tasks)
                }
            }
        }
        
        // MARK: - 筛选和排序栏
        private var filterAndSortBar: some View {
            VStack(spacing: 10) {
                // 筛选器（只在列表视图显示）
                if viewModel.viewMode == .list {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                FilterButton(
                                    title: filter.rawValue,
                                    isSelected: viewModel.selectedFilter == filter
                                ) {
                                    viewModel.selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 排序器（始终显示）
                Picker("排序", selection: $viewModel.selectedSort) {
                    ForEach(TaskSort.allCases, id: \.self) { sort in
                        Text(sort.rawValue).tag(sort)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
        }
        
        // MARK: - 任务列表
        private var taskList: some View {
            List {
                ForEach(viewModel.filteredTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task).environmentObject(focusViewModel)) {
                        TaskRowView(task: task, viewModel: viewModel, focusViewModel: focusViewModel)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let task = viewModel.filteredTasks[index]
                        viewModel.deleteTask(task, context: modelContext)
                    }
                }
            }
            .listStyle(.plain)
        }
        
        // MARK: - 看板视图
        private var kanbanView: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 15) {
                    // 待办列
                    KanbanColumn(
                        title: "待办",
                        tasks: viewModel.todoTasks,
                        status: .todo,
                        color: .blue,
                        viewModel: viewModel,
                        context: modelContext
                    )
                    
                    // 进行中列
                    KanbanColumn(
                        title: "进行中",
                        tasks: viewModel.doingTasks,
                        status: .doing,
                        color: .orange,
                        viewModel: viewModel,
                        context: modelContext
                    )
                    
                    // 已完成列
                    KanbanColumn(
                        title: "已完成",
                        tasks: viewModel.doneTasks,
                        status: .done,
                        color: .green,
                        viewModel: viewModel,
                        context: modelContext
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        
        // MARK: - 日历视图
        private var calendarView: some View {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 月份选择器
                        monthPicker
                        
                        // 日历网格
                        calendarGrid
                        
                        // 选中日期的任务列表
                        if let selectedDate = viewModel.selectedCalendarDate {
                            selectedDateTasks(selectedDate)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        
        // MARK: - 月份选择器
        private var monthPicker: some View {
            HStack {
                Button(action: {
                    // 上一个月
                    if let currentMonth = viewModel.selectedCalendarMonth {
                        viewModel.selectedCalendarMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let month = viewModel.selectedCalendarMonth {
                    Text(DateUtils.formatDate(month, format: "yyyy年MM月"))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button(action: {
                    // 下一个月
                    if let currentMonth = viewModel.selectedCalendarMonth {
                        viewModel.selectedCalendarMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        
        // MARK: - 日历网格
        private var calendarGrid: some View {
            VStack(spacing: 0) {
                // 星期标题
                HStack(spacing: 0) {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                        Text(weekday)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 10)
                
                // 日期网格
                let days = calculateCalendarDays()
                let calendar = Calendar.current
                let month = viewModel.selectedCalendarMonth ?? Date()
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
                
                // 网格布局
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                        CalendarDayCell(
                            date: date,
                            isCurrentMonth: date != nil && calendar.isDate(date!, equalTo: monthStart, toGranularity: .month),
                            isToday: date != nil && calendar.isDateInToday(date!),
                            tasks: date != nil ? tasksForDate(date!) : [],
                            onDateTap: { selectedDate in
                                viewModel.selectedCalendarDate = selectedDate
                            }
                        )
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        
        // MARK: - 计算日历日期
        private func calculateCalendarDays() -> [Date?] {
            let calendar = Calendar.current
            let month = viewModel.selectedCalendarMonth ?? Date()
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
                  let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
                return []
            }
            
            let firstWeekday = calendar.component(.weekday, from: monthStart) - 1 // 0=周日
            var days: [Date?] = []
            
            // 上个月的日期（填充第一周）
            for i in 0..<firstWeekday {
                if let date = calendar.date(byAdding: .day, value: -firstWeekday + i, to: monthStart) {
                    days.append(date)
                } else {
                    days.append(nil)
                }
            }
            
            // 当月的日期
            for day in monthRange {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                    days.append(date)
                }
            }
            
            // 下个月的日期（填充最后一周）
            let totalCells = ((days.count + 6) / 7) * 7
            while days.count < totalCells {
                if let lastDate = days.last ?? monthStart,
                   let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate) {
                    days.append(nextDate)
                } else {
                    days.append(nil)
                }
            }
            
            return days
        }
        
        // 获取指定日期的任务（基于创建日期，不考虑其他因素）
        private func tasksForDate(_ date: Date) -> [Task] {
            let calendar = Calendar.current
            // 直接使用allTasks，不考虑筛选条件，只按任务的创建日期（createdAt）进行区分
            return viewModel.allTasks.filter { task in
                return calendar.isDate(task.createdAt, inSameDayAs: date)
            }
        }
        
        // MARK: - 选中日期的任务列表
        private func selectedDateTasks(_ date: Date) -> some View {
            let tasks = tasksForDate(date)
            
            return VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(DateUtils.formatDate(date, format: "MM月dd日"))
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(tasks.count) 个任务")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                if tasks.isEmpty {
                    VStack {
                        Text("该日期没有任务")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    ForEach(tasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task).environmentObject(focusViewModel)) {
                            TaskRowView(task: task, viewModel: viewModel, focusViewModel: focusViewModel)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        
        // MARK: - 空状态
        private var emptyState: some View {
            VStack(spacing: 20) {
                Image(systemName: "checklist")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("暂无任务")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Button("创建任务") {
                    viewModel.editingTask = nil
                    viewModel.showTaskForm = true
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - 任务行视图
    struct TaskRowView: View {
        let task: Task
        @ObservedObject var viewModel: TasksViewModel
        @ObservedObject var focusViewModel: FocusViewModel
        @Environment(\.modelContext) private var modelContext
        
        var body: some View {
            VStack(spacing: 0) {
                // 主要内容区域
                HStack(alignment: .center, spacing: 10) {
                    // 左侧：标签图标（更小尺寸）
                    tagIconIndicator
                        .frame(width: 24, height: 24)
                    
                    // 中间：任务信息（占据剩余空间）
                    VStack(alignment: .leading, spacing: 4) {
                        // 任务名称（更小字体）
                        Text(task.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .strikethrough(task.status == .done)
                        
                        // 进度条（如果有目标，更小更紧凑，放在名称下方）
                        if task.totalGoal > 0 {
                            ProgressView(value: task.progressPercentage)
                                .tint(taskColor(task.colorTag))
                                .frame(height: 2)
                        }
                        
                        // 元数据行：日期和标签（单行紧凑显示）
                        HStack(spacing: 6) {
                            // 创建日期
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(DateUtils.formatDate(task.createdAt, format: "MM-dd"))
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                            
                            // 截止日期（如果有）
                            if let dueDate = task.dueDate {
                                HStack(spacing: 3) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10))
                                    Text(DateUtils.formatDate(dueDate, format: "MM-dd"))
                                        .font(.caption2)
                                }
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                            }
                            
                            // 标签（每个任务只能有一个标签）
                            if let firstTag = task.tags.first {
                                Text(firstTag)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(getTagColor(for: firstTag))
                                    .foregroundColor(.white)
                                    .cornerRadius(3)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 右侧：快速开始专注按钮（更小尺寸）
                    Button(action: {
                        focusViewModel.selectedTask = task
                        NotificationCenter.default.post(name: NSNotification.Name("SwitchToFocusTab"), object: nil)
                    }) {
                        Image(systemName: "timer")
                            .foregroundColor(AppColors.primary)
                            .font(.system(size: 20))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                
                // 分隔线（清晰的灰色线条，从图标右侧开始）
            }
            .contentShape(Rectangle())
        }
        
        // 标签图标指示器（显示标签的icon）
        @Query private var tags: [Tag]
        
        @ViewBuilder
        private var tagIconIndicator: some View {
            // 获取第一个标签的icon（更小尺寸，紧凑显示）
            if let firstTagName = task.tags.first,
               let tag = tags.first(where: { $0.name == firstTagName }),
               let icon = tag.icon {
                // 如果有icon，显示带背景的icon（更小）
                ZStack {
                    Circle()
                        .fill(Color(hex: tag.color).opacity(0.15))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: icon)
                        .foregroundColor(Color(hex: tag.color))
                        .font(.system(size: 12, weight: .medium))
                }
            } else {
                // 如果没有icon，显示颜色圆圈（更小）
                Circle()
                    .fill(getTaskTagColor(task))
                    .frame(width: 24, height: 24)
            }
        }
        
        // 获取任务标签颜色（使用第一个标签的颜色）
        private func getTaskTagColor(_ task: Task) -> Color {
            // 如果任务有标签，尝试从Tag模型中获取第一个标签的颜色
            if let firstTagName = task.tags.first {
                if let tag = tags.first(where: { $0.name == firstTagName }) {
                    return Color(hex: tag.color)
                }
            }
            // 如果没有标签或找不到Tag，使用任务的colorTag
            return taskColor(task.colorTag)
        }
        
        private func taskColor(_ hex: String) -> Color {
            // 尝试解析hex颜色，失败则返回默认蓝色
            let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            guard trimmed.count == 6 || trimmed.count == 3 || trimmed.count == 8 else {
                return .blue
            }
            return Color(hex: hex)
        }
        
        // 获取标签颜色（用于标签框背景）
        private func getTagColor(for tagName: String) -> Color {
            // 如果任务有标签，尝试从Tag模型中获取标签的颜色
            if let tag = tags.first(where: { $0.name == tagName }) {
                return Color(hex: tag.color)
            }
            // 如果没有找到，使用默认颜色
            return Color(.systemGray5)
        }
    }
    
    // MARK: - 筛选按钮
    struct FilterButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isSelected ? AppColors.primary : Color(.systemGray5))
                    .foregroundColor(isSelected ? .white : .primary)
                    .cornerRadius(20)
            }
        }
    }
    
    // MARK: - 任务表单视图
    struct TaskFormView: View {
        let task: Task?
        @ObservedObject var viewModel: TasksViewModel
        @Environment(\.modelContext) private var modelContext
        @Environment(\.dismiss) private var dismiss
        
        @Query private var tags: [Tag]
        @State private var name: String = ""
        @State private var taskDescription: String = ""
        @State private var totalGoal: Int = 60
        @State private var priority: TaskPriority = .medium
        @State private var taskDate: Date = Date() // 日期为必选项，默认为今日
        @State private var dueDate: Date? // 截止日期为可选项
        @State private var showDatePicker = false
        @State private var selectedTagNames: [String] = [] // 每个任务只能有一个标签，所以数组最多只有一个元素
        @State private var showTagPicker = false
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("基本信息") {
                        TextField("任务名称", text: $name)
                        TextField("任务描述（可选）", text: $taskDescription, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    Section("目标") {
                        Stepper("目标时长: \(totalGoal) 分钟", value: $totalGoal, in: 1...600, step: 15)
                    }
                    
                    Section("优先级") {
                        Picker("优先级", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                    }
                    
                    Section("日期") {
                        // 日期为必选项，默认为今日
                        DatePicker("日期", selection: $taskDate, displayedComponents: .date)
                    }
                    
                    Section("截止日期（可选）") {
                        Toggle("设置截止日期", isOn: Binding(
                            get: { dueDate != nil },
                            set: {
                                if $0 {
                                    if dueDate == nil {
                                        dueDate = Date() // 默认设置为今天
                                    }
                                } else {
                                    dueDate = nil
                                }
                            }
                        ))
                        
                        if dueDate != nil {
                            DatePicker("截止日期", selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                    
                    Section("标签（必选，只能选择一个）") {
                        if selectedTagNames.isEmpty {
                            Button(action: {
                                showTagPicker = true
                            }) {
                                HStack {
                                    Text("选择标签")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            // 只显示第一个标签（每个任务只能有一个标签）
                            if let firstTagName = selectedTagNames.first {
                                HStack {
                                    Text(firstTagName)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(AppColors.primary.opacity(0.2))
                                        .foregroundColor(AppColors.primary)
                                        .cornerRadius(8)
                                    
                                    Button(action: {
                                        selectedTagNames.removeAll()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            Button(action: {
                                showTagPicker = true
                            }) {
                                HStack {
                                    Text("编辑标签")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(task == nil ? "新建任务" : "编辑任务")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            saveTask()
                        }
                        .disabled(name.isEmpty || selectedTagNames.isEmpty || selectedTagNames.count != 1)
                    }
                }
                .sheet(isPresented: $showTagPicker) {
                    TagPickerView(selectedTags: $selectedTagNames)
                }
                .onAppear {
                    if let task = task {
                        name = task.name
                        taskDescription = task.taskDescription ?? ""
                        totalGoal = task.totalGoal
                        priority = task.priority
                        taskDate = task.createdAt // 编辑时使用创建日期
                        dueDate = task.dueDate
                        // 每个任务只能有一个标签，所以只取第一个
                        selectedTagNames = task.tags.isEmpty ? [] : [task.tags.first!]
                    } else {
                        // 新建任务时，默认日期为今日
                        taskDate = Date()
                    }
                }
            }
        }
        
        private func saveTask() {
            // 每个任务只能有一个标签，所以只取第一个
            let taskTag = selectedTagNames.first ?? ""
            let finalTags = taskTag.isEmpty ? [] : [taskTag]
            
            if let task = task {
                // 更新现有任务
                task.name = name
                task.taskDescription = taskDescription.isEmpty ? nil : taskDescription
                task.totalGoal = totalGoal
                task.priority = priority
                task.dueDate = dueDate
                task.createdAt = taskDate // 更新日期
                task.tags = finalTags // 只设置一个标签
                task.updatedAt = Date()
                viewModel.updateTask(task, context: modelContext)
            } else {
                // 创建新任务（使用taskDate作为创建日期）
                viewModel.createTask(
                    name: name,
                    taskDescription: taskDescription.isEmpty ? nil : taskDescription,
                    totalGoal: totalGoal,
                    priority: priority,
                    taskDate: taskDate, // 传递日期
                    dueDate: dueDate,
                    tags: finalTags, // 只传递一个标签
                    context: modelContext
                )
            }
            dismiss()
        }
    }
    
    
    #Preview {
        TasksView()
            .modelContainer(for: [Task.self])
            
    }

