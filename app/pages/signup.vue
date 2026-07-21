<template>
  <div class="container">
    <h2>新規会員登録</h2>
    <form @submit.prevent="handleSignUp" class="form">
      <div class="form-group">
        <label for="displayName">表示名 (ニックネーム)</label>
        <input v-model="displayName" type="text" id="displayName" required />
      </div>
      <div class="form-group">
        <label for="email">メールアドレス</label>
        <input v-model="email" type="email" id="email" required />
      </div>
      <div class="form-group">
        <label for="password">パスワード</label>
        <input v-model="password" type="password" id="password" required />
      </div>
      <button type="submit" class="btn btn-primary">アカウントを作成する</button>
    </form>
    <div class="links">
      <NuxtLink to="/signin">すでにアカウントをお持ちの方（ログイン）</NuxtLink>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const displayName = ref('')
const email = ref('')
const password = ref('')

const handleSignUp = () => {
  console.log('SignUp attempt:', displayName.value, email.value)
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
