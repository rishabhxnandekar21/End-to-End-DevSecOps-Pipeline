import Navbar from "../components/Navbar";
import TodoForm from "../components/TodoForm";
import TodoCard from "../components/TodoCard";

function Home() {
  return (
    <div className="container">
      <Navbar />

      <div className="dashboard">
        <TodoForm />

        <div className="todo-list">
          <TodoCard
            title="Learn Docker"
            description="Build first Docker image"
            status="Pending"
          />

          <TodoCard
            title="Learn Kubernetes"
            description="Deploy application on Minikube"
            status="Completed"
          />
        </div>
      </div>
    </div>
  );
}

export default Home;
