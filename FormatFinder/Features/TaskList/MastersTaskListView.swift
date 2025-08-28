import SwiftUI

struct TaskItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
    var order: Int = 0
}

struct MastersTaskListView: View {
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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Masters gradient background matching app theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        MastersColors.fairwayMist,
                        MastersColors.magnoliaLane
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Task Input Section with Masters styling
                    HStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "flag.fill")
                                .font(.system(size: 18))
                                .foregroundColor(MastersColors.mastersGreen)
                                .rotationEffect(.degrees(newTaskTitle.isEmpty ? 0 : 15))
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newTaskTitle)
                            
                            TextField("Add a task...", text: $newTaskTitle)
                                .font(MastersTypography.bodyText())
                                .foregroundColor(MastersColors.graphite)
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    addTask()
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(MastersColors.azaleaWhite)
                        .cornerRadius(MastersLayout.buttonRadius)
                        .shadow(color: MastersLayout.cardShadow.color, radius: MastersLayout.cardShadow.radius)
                        
                        Button(action: addTask) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(MastersColors.mastersGreen)
                                .background(
                                    Circle()
                                        .fill(MastersColors.azaleaWhite)
                                        .frame(width: 28, height: 28)
                                )
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(newTaskTitle.isEmpty ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: newTaskTitle.isEmpty)
                    }
                    .padding()
                    .background(
                        MastersColors.azaleaWhite
                            .shadow(color: MastersLayout.cardShadow.color, radius: 2, x: 0, y: 2)
                    )
                    
                    // Tasks List or Empty State
                    if tasks.isEmpty {
                        MastersTaskEmptyState(scale: $emptyStateScale, opacity: $emptyStateOpacity)
                    } else {
                        ScrollView {
                            // Pull to refresh indicator
                            if isRefreshing {
                                MastersRefreshIndicator()
                                    .padding(.top, 20)
                                    .padding(.bottom, 10)
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                            
                            LazyVStack(spacing: 12) {
                                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                                    MastersTaskRowView(
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
                                    .onDrop(of: [.text], delegate: MastersTaskDropDelegate(
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
                            await performRefresh()
                        }
                    }
                }
                
                // Masters-themed Confetti Overlay
                if showConfetti {
                    MastersConfettiView()
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
                            .foregroundColor(MastersColors.mastersGreen)
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
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            tasks.append(newTask)
            newTaskTitle = ""
        }
        
        animationOrchestrator.triggerHaptic(.light)
        
        tasksLoaded = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tasksLoaded = true
        }
    }
    
    private func deleteTask(task: TaskItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tasks.removeAll { $0.id == task.id }
        }
        
        animationOrchestrator.triggerHaptic(.medium)
    }
    
    private func completeTask(task: TaskItem, completed: Bool) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                tasks[index].isCompleted = completed
            }
            
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
    
    @MainActor
    private func performRefresh() async {
        isRefreshing = true
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        withAnimation(.spring()) {
            isRefreshing = false
        }
        
        animationOrchestrator.triggerHaptic(.medium)
    }
}

struct MastersTaskEmptyState: View {
    @Binding var scale: CGFloat
    @Binding var opacity: Double
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                // Masters-themed background circles
                Circle()
                    .fill(MastersColors.mastersGreen.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .offset(y: floatOffset)
                
                Circle()
                    .fill(MastersColors.augustaGold.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .offset(y: -floatOffset * 0.7)
                
                // Golf-themed icon
                Image(systemName: "flag.and.flag.filled.crossed")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MastersColors.mastersGreen, MastersColors.shadowGreen],
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
                    .font(MastersTypography.sectionHeader())
                    .foregroundColor(MastersColors.graphite)
                
                Text("Add your first task to get started")
                    .font(MastersTypography.bodyText())
                    .foregroundColor(MastersColors.silver)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(MastersColors.mastersGreen)
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

struct MastersTaskRowView: View {
    let task: TaskItem
    let index: Int
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
                .background(MastersColors.scoreRed)
                .cornerRadius(MastersLayout.cardRadius)
            }
            
            // Main task row
            HStack(spacing: 16) {
                // Masters-styled checkbox
                Button(action: {
                    onComplete(!task.isCompleted)
                }) {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                task.isCompleted ? MastersColors.mastersGreen : MastersColors.fog,
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)
                        
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(MastersColors.mastersGreen)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Task title with Masters typography
                Text(task.title)
                    .font(MastersTypography.bodyText())
                    .foregroundColor(task.isCompleted ? MastersColors.silver : MastersColors.graphite)
                    .strikethrough(task.isCompleted, color: MastersColors.silver)
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                    .lineLimit(2)
                
                Spacer()
                
                // Drag handle with golf theme
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16))
                    .foregroundColor(MastersColors.fog)
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: MastersLayout.cardRadius)
                    .fill(MastersColors.azaleaWhite)
                    .shadow(
                        color: MastersLayout.cardShadow.color,
                        radius: MastersLayout.cardShadow.radius,
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

struct MastersRefreshIndicator: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 20))
                .foregroundColor(MastersColors.mastersGreen)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Refreshing...")
                .font(MastersTypography.captionText())
                .foregroundColor(MastersColors.silver)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(MastersColors.mastersGreen.opacity(0.1))
        )
    }
}

struct MastersConfettiView: View {
    @State private var confettiPieces: [MastersConfettiPiece] = []
    
    let colors: [Color] = [
        MastersColors.mastersGreen,
        MastersColors.augustaGold,
        MastersColors.eagleGold,
        MastersColors.azaleaPink,
        MastersColors.shadowGreen
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    MastersConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
    }
    
    private func createConfetti(in size: CGSize) {
        for i in 0..<40 {
            let piece = MastersConfettiPiece(
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

struct MastersConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let delay: Double
    let rotation = Double.random(in: 0...360)
    let size = CGFloat.random(in: 8...16)
}

struct MastersConfettiPieceView: View {
    let piece: MastersConfettiPiece
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

struct MastersTaskDropDelegate: DropDelegate {
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

#Preview {
    MastersTaskListView()
        .environmentObject(TimeEnvironmentService.shared)
}