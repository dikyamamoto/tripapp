<template>
  <div class="container">
    <h2>プロフィール設定</h2>
    <form @submit.prevent="saveProfile" class="form">
      <div class="form-group">
        <label for="displayName">表示名 (ニックネーム)</label>
        <input v-model="displayName" type="text" id="displayName" required />
      </div>
      <button type="submit" class="btn btn-primary">変更を保存する</button>
    </form>
    
    <button @click="logout" class="btn btn-secondary logout-btn">ログアウト</button>
    <button @click="goBack" class="btn btn-link">戻る</button>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const displayName = ref('あなた (自分)')

const saveProfile = () => {
  alert('プロフィールを保存しました！')
  navigateTo('/trips')
}

const logout = () => {
  if (confirm('ログアウトしますか？')) {
    navigateTo('/')
  }
}

const goBack = () => {
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
  border: none;
  border-radius: 4px;
  font-weight: bold;
  cursor: pointer;
  width: 100%;
  max-width: 300px;
  margin-bottom: 10px;
}
.btn-primary {
  background-color: #007bff;
  color: white;
}
.btn-secondary {
  background-color: #6c757d;
  color: white;
}
.btn-link {
  background: none;
  color: #007bff;
  text-decoration: underline;
}
.logout-btn {
  margin-top: 20px;
}
</style>
