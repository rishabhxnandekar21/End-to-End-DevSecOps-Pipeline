function TodoForm() {
  return (
    <div className="todo-form">
      <h2>Add Todo</h2>

      <input type="text" placeholder="Todo Title" />

      <textarea placeholder="Description"></textarea>

      <button>Add Todo</button>
    </div>
  );
}

export default TodoForm;
