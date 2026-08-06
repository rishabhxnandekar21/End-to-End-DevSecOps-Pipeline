import { useEffect, useState } from "react";
import Navbar from "../components/Navbar";
import TodoForm from "../components/TodoForm";
import TodoCard from "../components/TodoCard";
import { getTodos, createTodo } from "../services/api";

function Home() {
  const [todos, setTodos] = useState([]);

  // Fetch all todos
  const fetchTodos = async () => {
    try {
      const response = await getTodos();
      setTodos(response.data.data);
    } catch (error) {
      console.error("Failed to fetch todos:", error);
    }
  };

  useEffect(() => {
    fetchTodos();
  }, []);

  // Create new todo
  const handleAddTodo = async (todoData) => {
    try {
      await createTodo(todoData);
      fetchTodos();
    } catch (error) {
      console.error("Failed to create todo:", error);
    }
  };

  return (
    <div className="container">
      <Navbar />

      <div className="dashboard">
        <TodoForm onAddTodo={handleAddTodo} />

        <div className="todo-list">
          {todos.length === 0 ? (
            <p>No todos found.</p>
          ) : (
            todos.map((todo) => (
              <TodoCard
                key={todo.id}
                title={todo.title}
                description={todo.description}
                status={todo.status}
              />
            ))
          )}
        </div>
      </div>
    </div>
  );
}

export default Home;
