import { useState } from "react";

function TodoForm({ onAddTodo }) {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();

    if (!title.trim()) {
      alert("Title is required");
      return;
    }

    onAddTodo({
      title,
      description,
    });

    setTitle("");
    setDescription("");
  };

  return (
    <form className="todo-form" onSubmit={handleSubmit}>
      <h2>Add Todo</h2>

      <input
        type="text"
        placeholder="Todo Title"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
      />

      <textarea
        placeholder="Description"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />

      <button type="submit">Add Todo</button>
    </form>
  );
}

export default TodoForm;
