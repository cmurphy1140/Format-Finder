import SwiftUI

struct TaskItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
    var order: Int = 0
}

struct EnhancedTaskListView: View {
    @State private var tasks: [TaskItem] = []
    @State private var newTaskTitle: String = ""
    @State private var isRefreshing = false
    @State private var showConfetti = false
    @State private var tasksLoaded = false
    @State private var draggedTask: TaskItem?
    @State private var emptyStateScale: CGFloat = 0.8
    @State private var emptyStateOpacity: Double = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Task Input Section
                    HStack(spacing: 12) {
                        TextField("Add a new task...", text: $newTaskTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                addTask()
                            }
                        
                        Button(action: addTask) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(newTaskTitle.isEmpty ? 0 : 180))
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newTaskTitle)
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                    
                    // Tasks List or Empty State
                    if tasks.isEmpty {
                        EmptyStateView(scale: $emptyStateScale, opacity: $emptyStateOpacity)
                    } else {
                        ScrollView {
                            // Pull to refresh indicator
                            if isRefreshing {
                                RefreshIndicator()
                                    .padding(.top, 20)
                                    .padding(.bottom, 10)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                            
                            LazyVStack(spacing: 8) {
                                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                                    EnhancedTaskRowView(
                                        task: task,
                                        index: index,
                                        onComplete: { completed in
                                            completeTask(task: task, completed: completed)
                                        },
                                        onDelete: {
                                            deleteTask(task: task)
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
                                        self.draggedTask = task
                                        return NSItemProvider(object: String(task.id.uuidString) as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: TaskDropDelegate(
                                        task: task,
                                        tasks: $tasks,
                                        draggedTask: $draggedTask
                                    ))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .refreshable {
                            await performRefresh()
                        }
                    }
                }
                
                // Confetti Overlay
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !tasks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .onAppear {
                animateEmptyState()
                loadTasksWithAnimation()
            }
        }
    }
    
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
        
        // Add with spring animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            tasks.append(newTask)
            newTaskTitle = ""
        }
        
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Reset loaded state for stagger animation
        tasksLoaded = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tasksLoaded = true
        }
    }
    
    private func deleteTask(task: TaskItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tasks.removeAll { $0.id == task.id }
        }
        
        // Medium haptic feedback for delete
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func completeTask(task: TaskItem, completed: Bool) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                tasks[index].isCompleted = completed
            }
            
            if completed {
                // Success haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                
                // Show confetti for completion
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showConfetti = false
                    }
                }
            } else {
                // Light haptic for uncomplete
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    @MainActor
    private func performRefresh() async {
        isRefreshing = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        withAnimation(.spring()) {
            isRefreshing = false
        }
        
        // Haptic feedback on refresh complete
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

struct EmptyStateView: View {
    @Binding var scale: CGFloat
    @Binding var opacity: Double
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                // Background circles for depth
                Circle()
                    .fill(Color.blue.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .offset(y: floatOffset)
                
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .offset(y: -floatOffset * 0.7)
                
                // Main icon
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: floatOffset * 0.5)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            
            VStack(spacing: 12) {
                Text("No Tasks Yet")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Add your first task to get started")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
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

struct EnhancedTaskRowView: View {
    let task: TaskItem
    let index: Int
    let onComplete: (Bool) -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var showDeleteButton = false
    @State private var offset: CGFloat = 0
    
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
                .background(Color.red)
                .cornerRadius(12)
            }
            
            // Main task row
            HStack(spacing: 16) {
                // Checkbox button with animation
                Button(action: {
                    onComplete(!task.isCompleted)
                }) {
                    ZStack {
                        Circle()
                            .strokeBorder(task.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
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
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                    .strikethrough(task.isCompleted, color: .gray)
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                    .lineLimit(2)
                
                Spacer()
                
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16))
                    .foregroundColor(.gray.opacity(0.4))
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
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
            // Trigger reorder mode
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

struct RefreshIndicator: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Refreshing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
    }
    
    private func createConfetti(in size: CGSize) {
        for i in 0..<50 {
            let piece = ConfettiPiece(
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

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let delay: Double
    let rotation = Double.random(in: 0...360)
    let size = CGFloat.random(in: 8...16)
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
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

struct TaskDropDelegate: DropDelegate {
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
        
        // Haptic feedback for reorder
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    EnhancedTaskListView()
}