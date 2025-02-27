<!--
Copyright 2018-2022 Cargill Incorporated

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

<template>
  <div class="auth-container">
    <toast toast-type="error" :active="error" v-on:toast-action="clearError">
      {{ error }}
    </toast>
    <div class="auth-wrapper">
      <form class="auth-form" @submit.prevent="login">
        <label class= "form-label">
          <div>Email</div>
          <input
            v-focus
            class="form-input"
            type="email"
            v-model="email"
            data-cy="email"
          />
        </label>
        <label class="form-label">
          <div>Password</div>
          <input
            class="form-input"
            type="password"
            v-model="password"
            data-cy="password"
          />
        </label>
        <div class="submit-container">
          <button class="btn-action large" type="submit" data-cy="submit" :disabled="!canSubmit">
            <div v-if="submitting" class="spinner" />
            <div class="btn-text" v-else> Log In </div>
          </button>
          <div class="form-link">
            Don't have an account yet?
            <router-link to="/register">
              Click here to register.
            </router-link>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script lang="ts">
import { Vue, Component } from 'vue-property-decorator';
import Toast from '../components/Toast.vue';

@Component({
  components: { Toast },
})
export default class Login extends Vue {
  email = '';
  password = '';
  submitting = false;
  error = '';

  get canSubmit() {
    if (!this.submitting &&
        this.email !== '' &&
        this.password !== '') {
      return true;
    }
    return false;
  }

  setError(message: string) {
    this.error = message;
    setTimeout(() => {
      this.clearError();
    }, 6000);
  }

  clearError() {
    this.error = '';
  }

  async login() {
    this.submitting = true;
    try {
      await this.$store.dispatch('user/authenticate', {
        email: this.email,
        password: this.password,
      });

      this.$router.push({ name: 'dashboard' });
    } catch (e) {
      this.setError(e.message);
    }
    this.submitting = false;
  }
}
</script>
