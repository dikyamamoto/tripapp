<template>
  <div class="container">
    <h1>TripApp (仮称)</h1>
    <p>旅行計画の共有と、割り勘の自動計算をワンタップで！</p>
    <div class="actions">
      <NuxtLink to="/signup" class="btn btn-primary">新しくアカウントを作る</NuxtLink>
      <NuxtLink to="/signin" class="btn btn-secondary">ログインする</NuxtLink>
    </div>
  </div>
</template>

<style scoped>
.container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  font-family: sans-serif;
  text-align: center;
  padding: 20px;
}
.actions {
  margin-top: 20px;
  display: flex;
  gap: 10px;
}
.btn {
  padding: 10px 20px;
  text-decoration: none;
  border-radius: 5px;
  font-weight: bold;
}
.btn-primary {
  background-color: #007bff;
  color: white;
}
.btn-secondary {
  background-color: #6c757d;
  color: white;
}
</style>
