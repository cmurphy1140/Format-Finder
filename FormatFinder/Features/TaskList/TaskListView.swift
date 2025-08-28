import SwiftUI

struct TaskItem: Identifiable {
    let id = UUID()
    var title: String
}

struct TaskListView: View {
    @State private var tasks: [TaskItem] = []
    @State private var newTaskTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
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
                    }
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                
                // Tasks List
                if tasks.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                        Text("No tasks yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Add your first task above")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(tasks) { task in
                            TaskRowView(title: task.title)
                        }
                        .onDelete(perform: deleteTask)
                    }
                    .listStyle(PlainListStyle())
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
        }
    }
    
    private func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tasks.append(TaskItem(title: trimmedTitle))
            newTaskTitle = ""
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tasks.remove(atOffsets: offsets)
        }
    }
}

struct TaskRowView: View {
    let title: String
    @State private var isCompleted: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isCompleted.toggle()
                }
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : .gray)
                    .scaleEffect(isCompleted ? 1.1 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(title)
                .font(.body)
                .strikethrough(isCompleted, color: .gray)
                .foregroundColor(isCompleted ? .gray : .primary)
                .animation(.easeInOut(duration: 0.2), value: isCompleted)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    TaskListView()
}