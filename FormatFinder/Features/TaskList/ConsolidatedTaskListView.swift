import SwiftUI

// MARK: - Task Models
struct TaskItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
    var order: Int = 0
}

// MARK: - Theme Configuration Protocol
protocol TaskListTheme {
    // Colors
    var primaryColor: Color { get }
    var backgroundColor: Color { get }
    var cardColor: Color { get }
    var textColor: Color { get }
    var secondaryTextColor: Color { get }
    var successColor: Color { get }
    var errorColor: Color { get }
    var borderColor: Color { get }
    
    // Typography
    var titleFont: Font { get }
    var bodyFont: Font { get }
    var captionFont: Font { get }
    
    // Layout
    var cardRadius: CGFloat { get }
    var standardSpacing: CGFloat { get }
    var cardShadowColor: Color { get }
    var cardShadowRadius: CGFloat { get }
}

// MARK: - Masters Theme Implementation
struct MastersTaskListTheme: TaskListTheme {
    var primaryColor: Color { MastersColors.mastersGreen }
    var backgroundColor: Color { MastersColors.fairwayMist }
    var cardColor: Color { MastersColors.azaleaWhite }
    var textColor: Color { MastersColors.graphite }
    var secondaryTextColor: Color { MastersColors.silver }
    var successColor: Color { MastersColors.mastersGreen }
    var errorColor: Color { MastersColors.scoreRed }
    var borderColor: Color { MastersColors.fog }
    
    var titleFont: Font { MastersTypography.sectionHeader() }
    var bodyFont: Font { MastersTypography.bodyText() }
    var captionFont: Font { MastersTypography.captionText() }
    
    var cardRadius: CGFloat { MastersLayout.cardRadius }
    var standardSpacing: CGFloat { MastersLayout.standardSpacing }
    var cardShadowColor: Color { MastersLayout.cardShadow.color }
    var cardShadowRadius: CGFloat { MastersLayout.cardShadow.radius }
}

// MARK: - Default Theme Implementation
struct DefaultTaskListTheme: TaskListTheme {
    var primaryColor: Color { .blue }
    var backgroundColor: Color { Color(UIColor.systemGroupedBackground) }
    var cardColor: Color { Color(UIColor.systemBackground) }
    var textColor: Color { .primary }
    var secondaryTextColor: Color { .secondary }
    var successColor: Color { .green }
    var errorColor: Color { .red }
    var borderColor: Color { .gray.opacity(0.3) }
    
    var titleFont: Font { .title2.weight(.semibold) }
    var bodyFont: Font { .body }
    var captionFont: Font { .caption }
    
    var cardRadius: CGFloat { 12 }
    var standardSpacing: CGFloat { 16 }
    var cardShadowColor: Color { .black.opacity(0.05) }
    var cardShadowRadius: CGFloat { 3 }
}

// MARK: - Consolidated Task List View
struct ConsolidatedTaskListView: View {
    // MARK: - Properties
    let theme: TaskListTheme
    let useAdvancedFeatures: Bool
    let showGolfTheme: Bool
    
    @State private var tasks: [TaskItem] = []
    @State private var newTaskTitle: String = ""
    @State private var isRefreshing = false
    @State private var showConfetti = false
    @State private var tasksLoaded = false
    @State private var draggedTask: TaskItem?
    @State private var emptyStateScale: CGFloat = 0.8
    @State private var emptyStateOpacity: Double = 0
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var animationOrchestrator = AnimationOrchestrator.shared
    @EnvironmentObject var timeEnvironmentService: TimeEnvironmentService
    
    // MARK: - Initializers
    init(theme: TaskListTheme = MastersTaskListTheme(), useAdvancedFeatures: Bool = true, showGolfTheme: Bool = true) {
        self.theme = theme
        self.useAdvancedFeatures = useAdvancedFeatures
        self.showGolfTheme = showGolfTheme
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: 0) {
                    // Task Input Section
                    taskInputSection
                    
                    // Tasks List or Empty State
                    if tasks.isEmpty {
                        emptyStateView
                    } else {
                        tasksListView
                    }
                }
                
                // Confetti Overlay
                if showConfetti && useAdvancedFeatures {
                    confettiView
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
            .navigationTitle("Task List")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !tasks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            .onAppear {
                if useAdvancedFeatures {
                    animateEmptyState()
                    loadTasksWithAnimation()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var backgroundView: some View {
        if showGolfTheme {
            LinearGradient(
                gradient: Gradient(colors: [theme.backgroundColor, theme.cardColor]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        } else {
            theme.backgroundColor.ignoresSafeArea()
        }
    }
    
    private var taskInputSection: some View {
        HStack(spacing: theme.standardSpacing) {
            inputFieldSection
            addButton
        }
        .padding()
        .background(
            theme.cardColor
                .shadow(color: theme.cardShadowColor, radius: 2, x: 0, y: 2)
        )
    }
    
    private var inputFieldSection: some View {
        HStack(spacing: 12) {
            if showGolfTheme {
                Image(systemName: "flag.fill")
                    .font(.system(size: 18))
                    .foregroundColor(theme.primaryColor)
                    .rotationEffect(.degrees(newTaskTitle.isEmpty ? 0 : 15))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newTaskTitle)
            }
            
            TextField("Add a task...", text: $newTaskTitle)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)
                .focused($isTextFieldFocused)
                .onSubmit {
                    addTask()
                }
        }
        .padding(.horizontal, theme.standardSpacing)
        .padding(.vertical, 12)
        .background(theme.cardColor)
        .cornerRadius(theme.cardRadius)
        .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius)
    }
    
    private var addButton: some View {
        Button(action: addTask) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: useAdvancedFeatures ? 32 : 24))
                .foregroundColor(theme.primaryColor)
                .background(
                    Circle()
                        .fill(theme.cardColor)
                        .frame(width: useAdvancedFeatures ? 28 : 20, height: useAdvancedFeatures ? 28 : 20)
                )
        }
        .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(newTaskTitle.isEmpty ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: newTaskTitle.isEmpty)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if useAdvancedFeatures {
            AdvancedEmptyStateView(theme: theme, showGolfTheme: showGolfTheme, scale: $emptyStateScale, opacity: $emptyStateOpacity)
        } else {
            BasicEmptyStateView(theme: theme)
        }
    }
    
    @ViewBuilder
    private var tasksListView: some View {
        if useAdvancedFeatures {
            AdvancedTasksListView(
                tasks: $tasks,
                draggedTask: $draggedTask,
                tasksLoaded: $tasksLoaded,
                isRefreshing: $isRefreshing,
                theme: theme,
                onComplete: completeTask,
                onDelete: deleteTask,
                onRefresh: performRefresh
            )
        } else {
            BasicTasksListView(
                tasks: $tasks,
                theme: theme,
                onComplete: completeTask,
                onDelete: deleteTask
            )
        }
    }
    
    @ViewBuilder
    private var confettiView: some View {
        if showGolfTheme {
            MastersConfettiView()
        } else {
            GenericConfettiView(theme: theme)
        }
    }
    
    // MARK: - Actions
    
    private func animateEmptyState() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            emptyStateScale = 1.0
            emptyStateOpacity = 1.0
        }
    }
    
    private func loadTasksWithAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            tasksLoaded = true
        }
    }
    
    private func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let newTask = TaskItem(title: trimmedTitle, order: tasks.count)
        
        let animation: Animation = useAdvancedFeatures ? 
            .spring(response: 0.4, dampingFraction: 0.6) : 
            .easeInOut(duration: 0.3)
        
        withAnimation(animation) {
            tasks.append(newTask)
            newTaskTitle = ""
        }
        
        if useAdvancedFeatures {
            animationOrchestrator.triggerHaptic(.light)
            
            tasksLoaded = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                tasksLoaded = true
            }
        }
    }
    
    private func deleteTask(task: TaskItem) {
        let animation: Animation = useAdvancedFeatures ?
            .spring(response: 0.3, dampingFraction: 0.7) :
            .easeInOut(duration: 0.3)
        
        withAnimation(animation) {
            tasks.removeAll { $0.id == task.id }
        }
        
        if useAdvancedFeatures {
            animationOrchestrator.triggerHaptic(.medium)
        }
    }
    
    private func completeTask(task: TaskItem, completed: Bool) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let animation: Animation = useAdvancedFeatures ?
                .spring(response: 0.3, dampingFraction: 0.7) :
                .easeInOut(duration: 0.3)
            
            withAnimation(animation) {
                tasks[index].isCompleted = completed
            }
            
            if useAdvancedFeatures {
                if completed {
                    animationOrchestrator.triggerHaptic(.success)
                    
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showConfetti = false
                        }
                    }
                } else {
                    animationOrchestrator.triggerHaptic(.light)
                }
            }
        }
    }
    
    @MainActor
    private func performRefresh() async {
        guard useAdvancedFeatures else { return }
        
        isRefreshing = true
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        withAnimation(.spring()) {
            isRefreshing = false
        }
        
        animationOrchestrator.triggerHaptic(.medium)
    }
}

// MARK: - Supporting Views

struct BasicEmptyStateView: View {
    let theme: TaskListTheme
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(theme.secondaryTextColor)
            
            VStack(spacing: 12) {
                Text("No Tasks Yet")
                    .font(theme.titleFont)
                    .foregroundColor(theme.textColor)
                
                Text("Add your first task above")
                    .font(theme.captionFont)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
        }
    }
}

struct AdvancedEmptyStateView: View {
    let theme: TaskListTheme
    let showGolfTheme: Bool
    @Binding var scale: CGFloat
    @Binding var opacity: Double
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: showGolfTheme ? 32 : 24) {
            Spacer()
            
            ZStack {
                // Background circles for depth
                Circle()
                    .fill(theme.primaryColor.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .offset(y: floatOffset)
                
                Circle()
                    .fill(theme.primaryColor.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .offset(y: -floatOffset * 0.7)
                
                // Main icon
                Image(systemName: showGolfTheme ? "flag.and.flag.filled.crossed" : "list.bullet.clipboard")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primaryColor, theme.primaryColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: floatOffset * 0.5)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            
            VStack(spacing: 16) {
                Text("No Tasks Yet")
                    .font(theme.titleFont)
                    .foregroundColor(theme.textColor)
                
                Text("Add your first task to get started")
                    .font(theme.bodyFont)
                    .foregroundColor(theme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primaryColor)
                    .padding(.top, 8)
                    .offset(y: floatOffset * 0.3)
            }
            .opacity(opacity)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
    }
}

struct BasicTasksListView: View {
    @Binding var tasks: [TaskItem]
    let theme: TaskListTheme
    let onComplete: (TaskItem, Bool) -> Void
    let onDelete: (TaskItem) -> Void
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                BasicTaskRowView(
                    task: task,
                    theme: theme,
                    onComplete: { completed in
                        onComplete(task, completed)
                    }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    onDelete(tasks[index])
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct AdvancedTasksListView: View {
    @Binding var tasks: [TaskItem]
    @Binding var draggedTask: TaskItem?
    @Binding var tasksLoaded: Bool
    @Binding var isRefreshing: Bool
    let theme: TaskListTheme
    let onComplete: (TaskItem, Bool) -> Void
    let onDelete: (TaskItem) -> Void
    let onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            // Pull to refresh indicator
            if isRefreshing {
                RefreshIndicatorView(theme: theme)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    AdvancedTaskRowView(
                        task: task,
                        index: index,
                        theme: theme,
                        onComplete: { completed in
                            onComplete(task, completed)
                        },
                        onDelete: {
                            onDelete(task)
                        }
                    )
                    .opacity(tasksLoaded ? 1 : 0)
                    .offset(y: tasksLoaded ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.05),
                        value: tasksLoaded
                    )
                    .onDrag {
                        draggedTask = task
                        return NSItemProvider(object: String(task.id.uuidString) as NSString)
                    }
                    .onDrop(of: [.text], delegate: ConsolidatedTaskDropDelegate(
                        task: task,
                        tasks: $tasks,
                        draggedTask: $draggedTask
                    ))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .refreshable {
            await onRefresh()
        }
    }
}

struct BasicTaskRowView: View {
    let task: TaskItem
    let theme: TaskListTheme
    let onComplete: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                onComplete(!task.isCompleted)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? theme.successColor : theme.borderColor)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(task.title)
                .font(theme.bodyFont)
                .strikethrough(task.isCompleted, color: theme.secondaryTextColor)
                .foregroundColor(task.isCompleted ? theme.secondaryTextColor : theme.textColor)
                .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct AdvancedTaskRowView: View {
    let task: TaskItem
    let index: Int
    let theme: TaskListTheme
    let onComplete: (Bool) -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var showDeleteButton = false
    @State private var offset: CGFloat = 0
    @StateObject private var animationOrchestrator = AnimationOrchestrator.shared
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .frame(width: 60)
                }
                .frame(height: 60)
                .background(theme.errorColor)
                .cornerRadius(theme.cardRadius)
            }
            
            // Main task row
            HStack(spacing: 16) {
                // Checkbox button with animation
                Button(action: {
                    onComplete(!task.isCompleted)
                }) {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                task.isCompleted ? theme.successColor : theme.borderColor,
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)
                        
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(theme.successColor)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Task title
                Text(task.title)
                    .font(theme.bodyFont)
                    .foregroundColor(task.isCompleted ? theme.secondaryTextColor : theme.textColor)
                    .strikethrough(task.isCompleted, color: theme.secondaryTextColor)
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                    .lineLimit(2)
                
                Spacer()
                
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16))
                    .foregroundColor(theme.borderColor)
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: theme.cardRadius)
                    .fill(theme.cardColor)
                    .shadow(
                        color: theme.cardShadowColor,
                        radius: theme.cardShadowRadius,
                        x: 0,
                        y: 2
                    )
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < -20 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -50 {
                                offset = -80
                                showDeleteButton = true
                            } else {
                                offset = 0
                                showDeleteButton = false
                            }
                        }
                    }
            )
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.5) {
            animationOrchestrator.triggerHaptic(.medium)
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

struct RefreshIndicatorView: View {
    let theme: TaskListTheme
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 20))
                .foregroundColor(theme.primaryColor)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Refreshing...")
                .font(theme.captionFont)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(theme.primaryColor.opacity(0.1))
        )
    }
}

struct GenericConfettiView: View {
    let theme: TaskListTheme
    @State private var confettiPieces: [GenericConfettiPiece] = []
    
    var colors: [Color] {
        [theme.primaryColor, theme.successColor, theme.primaryColor.opacity(0.7)]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    GenericConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
    }
    
    private func createConfetti(in size: CGSize) {
        for i in 0..<50 {
            let piece = GenericConfettiPiece(
                color: colors.randomElement()!,
                startX: CGFloat.random(in: 0...size.width),
                startY: -20,
                endY: size.height + 20,
                delay: Double(i) * 0.02
            )
            confettiPieces.append(piece)
        }
    }
}

struct GenericConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let delay: Double
    let rotation = Double.random(in: 0...360)
    let size = CGFloat.random(in: 8...16)
}

struct GenericConfettiPieceView: View {
    let piece: GenericConfettiPiece
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var xOffset: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .rotationEffect(.degrees(piece.rotation))
            .position(x: piece.startX + xOffset, y: piece.startY + offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5).delay(piece.delay)) {
                    offset = piece.endY - piece.startY
                    xOffset = CGFloat.random(in: -50...50)
                    opacity = 0
                }
            }
    }
}

struct ConsolidatedTaskDropDelegate: DropDelegate {
    let task: TaskItem
    @Binding var tasks: [TaskItem]
    @Binding var draggedTask: TaskItem?
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedTask = draggedTask else { return false }
        
        let fromIndex = tasks.firstIndex(where: { $0.id == draggedTask.id })
        let toIndex = tasks.firstIndex(where: { $0.id == task.id })
        
        guard let from = fromIndex, let to = toIndex, from != to else { return false }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tasks.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
        
        AnimationOrchestrator.shared.triggerHaptic(.light)
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        AnimationOrchestrator.shared.triggerHaptic(.light)
    }
}

#Preview("Masters Theme") {
    ConsolidatedTaskListView(
        theme: MastersTaskListTheme(),
        useAdvancedFeatures: true,
        showGolfTheme: true
    )
    .environmentObject(TimeEnvironmentService.shared)
}

#Preview("Default Theme") {
    ConsolidatedTaskListView(
        theme: DefaultTaskListTheme(),
        useAdvancedFeatures: false,
        showGolfTheme: false
    )
}