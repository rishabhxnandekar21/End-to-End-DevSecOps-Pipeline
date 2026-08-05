function TodoCard({ title, description, status }) {
  return (
    <div className="todo-card">
      <h3>{title}</h3>

      <p>{description}</p>

      <span>{status}</span>

      <div className="actions">
        <button>Edit</button>
        <button>Delete</button>
      </div>
    </div>
  );
}

export default TodoCard;
