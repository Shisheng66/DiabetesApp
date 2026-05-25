// ============================================
// Vue 3 + Axios 集成示例
// ============================================

// 1. 安装依赖
// npm install axios

// 2. 创建 src/utils/request.js
import axios from 'axios'

const request = axios.create({
  baseURL: 'http://localhost:8080',
  timeout: 5000
})

// 请求拦截器
request.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

// 响应拦截器
request.interceptors.response.use(
  response => {
    return response.data
  },
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default request


// 3. 创建 src/api/auth.js
import request from '@/utils/request'

export function login(phone, password) {
  return request({
    url: '/api/auth/login',
    method: 'post',
    data: { phone, password }
  })
}

export function register(phone, password, role = 'PATIENT') {
  return request({
    url: '/api/auth/register',
    method: 'post',
    data: { phone, password, role }
  })
}

export function getCurrentUser() {
  return request({
    url: '/api/users/me',
    method: 'get'
  })
}


// 4. 创建 src/api/bloodGlucose.js
import request from '@/utils/request'

export function getBloodGlucoseRecords(params) {
  return request({
    url: '/api/blood-glucose/records',
    method: 'get',
    params
  })
}

export function addBloodGlucoseRecord(data) {
  return request({
    url: '/api/blood-glucose/records',
    method: 'post',
    data
  })
}

export function deleteBloodGlucoseRecord(id) {
  return request({
    url: `/api/blood-glucose/records/${id}`,
    method: 'delete'
  })
}


// 5. 在组件中使用 - Login.vue
<template>
  <div class="login-container">
    <el-form :model="form" label-width="80px">
      <el-form-item label="手机号">
        <el-input v-model="form.phone" placeholder="请输入手机号" />
      </el-form-item>
      <el-form-item label="密码">
        <el-input v-model="form.password" type="password" placeholder="请输入密码" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleLogin">登录</el-button>
        <el-button @click="handleRegister">注册</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { login, register } from '@/api/auth'
import { ElMessage } from 'element-plus'

const router = useRouter()
const form = ref({
  phone: '',
  password: ''
})

const handleLogin = async () => {
  try {
    const res = await login(form.value.phone, form.value.password)
    localStorage.setItem('token', res.accessToken)
    ElMessage.success('登录成功')
    router.push('/')
  } catch (error) {
    ElMessage.error('登录失败：' + error.message)
  }
}

const handleRegister = async () => {
  try {
    const res = await register(form.value.phone, form.value.password)
    localStorage.setItem('token', res.accessToken)
    ElMessage.success('注册成功')
    router.push('/')
  } catch (error) {
    ElMessage.error('注册失败：' + error.message)
  }
}
</script>


// 6. 创建 src/api/diet.js
import request from '@/utils/request'

export function getFoods(keyword = '', page = 0, size = 20) {
  return request({
    url: '/api/diet/foods',
    method: 'get',
    params: { keyword, page, size }
  })
}

export function getDietRecords(date, mealType = null) {
  return request({
    url: '/api/diet/records',
    method: 'get',
    params: { date, mealType }
  })
}

export function addDietRecord(data) {
  return request({
    url: '/api/diet/records',
    method: 'post',
    data
  })
}


// 7. 创建 src/api/exercise.js
import request from '@/utils/request'

export function getExerciseTypes() {
  return request({
    url: '/api/exercise/types',
    method: 'get'
  })
}

export function getExerciseRecords(params) {
  return request({
    url: '/api/exercise/records',
    method: 'get',
    params
  })
}

export function addExerciseRecord(data) {
  return request({
    url: '/api/exercise/records',
    method: 'post',
    data
  })
}


// 8. 创建 src/api/dashboard.js
import request from '@/utils/request'

export function getTodayDashboard() {
  return request({
    url: '/api/dashboard/today',
    method: 'get'
  })
}


// 9. 完整的使用示例 - Dashboard.vue
<template>
  <div class="dashboard">
    <h1>今日概览</h1>
    
    <!-- 最近血糖 -->
    <el-card>
      <h3>最近一次血糖</h3>
      <p v-if="dashboard.lastestGlucose">
        {{ dashboard.lastestGlucose.valueMmolL }} mmol/L
      </p>
      <p v-else>暂无数据</p>
    </el-card>

    <!-- 今日提醒 -->
    <el-card>
      <h3>今日提醒</h3>
      <ul>
        <li v-for="reminder in dashboard.reminders" :key="reminder.id">
          {{ reminder.content }}
        </li>
      </ul>
    </el-card>

    <!-- 食物列表 -->
    <el-table :data="foods" border>
      <el-table-column prop="name" label="食物名称" />
      <el-table-column prop="caloriesPer100g" label="热量 (kcal/100g)" />
      <el-table-column prop="carbsPer100g" label="碳水 (g/100g)" />
    </el-table>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getTodayDashboard } from '@/api/dashboard'
import { getFoods } from '@/api/diet'

const dashboard = ref({
  lastestGlucose: null,
  reminders: []
})

const foods = ref([])

onMounted(async () => {
  // 加载今日概览
  try {
    const data = await getTodayDashboard()
    dashboard.value = data
  } catch (error) {
    console.error('加载今日概览失败:', error)
  }

  // 加载食物列表
  try {
    const result = await getFoods('米饭')
    foods.value = result.content
  } catch (error) {
    console.error('加载食物列表失败:', error)
  }
})
</script>


// 10. 环境变量配置
// .env.development
VUE_APP_BASE_API = 'http://localhost:8080'

// .env.production
VUE_APP_BASE_API = 'https://api.yourdomain.com'

// 在 request.js 中使用
const request = axios.create({
  baseURL: process.env.VUE_APP_BASE_API || 'http://localhost:8080',
  timeout: 5000
})


// ============================================
// React + Axios 集成示例
// ============================================

// 1. 创建 src/utils/request.js (与 Vue 相同)

// 2. 创建 src/services/api.js
import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:8080',
  timeout: 5000
})

api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export const authAPI = {
  login: (phone, password) => 
    api.post('/api/auth/login', { phone, password }),
  
  register: (phone, password, role = 'PATIENT') =>
    api.post('/api/auth/register', { phone, password, role })
}

export const userAPI = {
  getCurrentUser: () => api.get('/api/users/me')
}

export const bloodGlucoseAPI = {
  getRecords: (params) => api.get('/api/blood-glucose/records', { params }),
  addRecord: (data) => api.post('/api/blood-glucose/records', data),
  deleteRecord: (id) => api.delete(`/api/blood-glucose/records/${id}`)
}

export const dietAPI = {
  getFoods: (keyword = '', page = 0, size = 20) =>
    api.get('/api/diet/foods', { params: { keyword, page, size } }),
  getRecords: (date, mealType = null) =>
    api.get('/api/diet/records', { params: { date, mealType } }),
  addRecord: (data) => api.post('/api/diet/records', data)
}

export const exerciseAPI = {
  getTypes: () => api.get('/api/exercise/types'),
  getRecords: (params) => api.get('/api/exercise/records', { params }),
  addRecord: (data) => api.post('/api/exercise/records', data)
}

export const dashboardAPI = {
  getToday: () => api.get('/api/dashboard/today')
}

// 3. 在 React 组件中使用
import React, { useState, useEffect } from 'react'
import { authAPI, dashboardAPI } from '../services/api'

function Login() {
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')

  const handleLogin = async (e) => {
    e.preventDefault()
    try {
      const res = await authAPI.login(phone, password)
      localStorage.setItem('token', res.data.accessToken)
      // 跳转到首页
    } catch (error) {
      alert('登录失败')
    }
  }

  return (
    <form onSubmit={handleLogin}>
      <input value={phone} onChange={e => setPhone(e.target.value)} placeholder="手机号" />
      <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="密码" />
      <button type="submit">登录</button>
    </form>
  )
}

function Dashboard() {
  const [dashboard, setDashboard] = useState(null)

  useEffect(() => {
    dashboardAPI.getToday().then(res => {
      setDashboard(res.data)
    })
  }, [])

  return (
    <div>
      <h1>今日概览</h1>
      {dashboard && <p>最近血糖：{dashboard.lastestGlucose?.valueMmolL}</p>}
    </div>
  )
}
