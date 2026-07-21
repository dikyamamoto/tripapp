<template>
  <div class="container">
    <h2>ログイン</h2>
    <form @submit.prevent="handleLogin" class="form">
      <div class="form-group">
        <label for="email">メールアドレス</label>
        <input v-model="email" type="email" id="email" required />
      </div>
      <div class="form-group">
        <label for="password">パスワード</label>
        <input v-model="password" type="password" id="password" required />
      </div>
      <button type="submit" class="btn btn-primary">ログイン</button>
    </form>
    <div class="links">
      <NuxtLink to="/signup">アカウントをお持ちでない方（新規登録）</NuxtLink>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const email = ref('')
const password = ref('')

const handleLogin = () => {
  console.log('Login attempt:', email.value)
  // 開発検証用に強制遷移できるようにします
  navigateTo('/trips')
}
</script>

<style scoped>
.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  font-family: sans-serif;
  padding: 20px;
}
.form {
  width: 100%;
  max-width: 300px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-bottom: 20px;
}
.form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}
input {
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
}
.btn {
  padding: 10px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  font-weight: bold;
  cursor: pointer;
}
.links {
  font-size: 0.9rem;
}
</style>
