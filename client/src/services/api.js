import axios from "axios";

const API = axios.create({
  baseURL: "/api",
  headers: {
    "Content-Type": "application/json",
  },
});

export const getTodos = () => API.get("/todos");

export const createTodo = (todo) => API.post("/todos", todo);

export const updateTodo = (id, todo) => API.put(`/todos/${id}`, todo);

export default API;
