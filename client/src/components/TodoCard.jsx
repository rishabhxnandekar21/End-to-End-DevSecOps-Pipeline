function TodoCard({ title, description, status }) {
  return (
    <div className="todo-card">
      <h3>{title}</h3>

      <p>{description}</p>

      <span>{status}</span>
    </div>
  );
}

export default TodoCard;
