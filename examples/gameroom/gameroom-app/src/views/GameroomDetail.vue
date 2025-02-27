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
  <div class="gameroom-detail-container">
    <modal v-if="displayModal" @close="closeNewGameModal">
      <h4 slot="title">New Game</h4>
      <div slot="body">
        <form class="modal-form" @submit.prevent="createGame">
          <label class="form-label">
            Game name
            <input class="form-input" type="text" v-model="newGameName" />
          </label>
          <div class="flex-container button-container">
            <button class="btn-action outline small"
                    type="reset"
                    @click.prevent="closeNewGameModal">
              <div class="btn-text">Cancel</div>
            </button>
            <button class="btn-action small" type="submit" :disabled="!canSubmitNewGame">
              <div v-if="submitting" class="spinner" />
              <div class="btn-text" v-else>Send</div>
            </button>
          </div>
        </form>
      </div>
    </modal>
    <div class="gameroom-information">
      <h2 class="gameroom-name">{{ gameroom.alias }}</h2>
      <span> {{ gemeroomMembers }} </span>
    </div>
        <div v-if="gameroom.status === 'Active'" class="data-container">
          <div class="header">
          <div class="tab-buttons">
          <button class="tab-button"
                  @click="selectTab(1)"
                  :disabled="gameroom.status !== 'Active'"
                  :class="{ 'is-active' : currentTab === 1 }">
            <div class="btn-text">all</div>
          </button >
          <button class="tab-button"
                  @click="selectTab(2)"
                  :disabled="gameroom.status !== 'Active'"
                  :class="{ 'is-active' : currentTab === 2 }">
            <div class="btn-text">your games</div>
          </button>
          <button class="tab-button"
                  @click="selectTab(3)"
                  :disabled="gameroom.status !== 'Active'"
                  :class="{ 'is-active' : currentTab === 3 }">
            <div class="btn-text">join</div>
          </button>
          <button class="tab-button"
                  @click="selectTab(4)"
                  :disabled="gameroom.status !== 'Active'"
                  :class="{ 'is-active' : currentTab === 4 }">
            <div class="btn-text">watch</div>
          </button>
          <button class="tab-button"
                  @click="selectTab(5)"
                  :disabled="gameroom.status !== 'Active'"
                  :class="{ 'is-active' : currentTab === 5 }">
            <div class="btn-text">archived</div>
          </button>
        </div>
        <button  :disabled="gameroom.status !== 'Active'" class="btn-action right" @click="showNewGameModal()">
          <div class="btn-text">New Game</div>
        </button>
        </div>
        <div class="filter-container">
          <input class="form-filter"
                :disabled="gameroom.status !== 'Active'"
                v-model="gameNameFilter" type="text"
                placeholder="Filter name..." />

        </div>
        <div class="cards-container" v-if="filteredGames.length > 0">
          <game-card
            class="card-container"
            v-for="(game, index) in filteredGames"
            :key="index"
            :game="game" />
         </div>
         <div class="placeholder-wrapper" v-else>
           <h3 class="tbl-placeholder">No games to show</h3>
         </div>
      </div>
    <div class="data-container" v-else>
      <loading message="Please wait while the gameroom is being set up" />
    </div>
  </div>
</template>

<script lang="ts">
import { Vue, Component } from 'vue-property-decorator';
import gamerooms from '@/store/modules/gamerooms';
import { gameIsOver, userIsInGame, userCanJoinGame} from '@/utils/xo-games';
import { Gameroom, Member, Game } from '@/store/models';
import Modal from '@/components/Modal.vue';
import GameCard from '@/components/GameCard.vue';
import store from '@/store';
import Loading from '@/components/Loading.vue';

@Component({
  components: { Modal, GameCard, Loading },
})
  export default class GameroomDetails extends Vue {
      gameNameFilter = '';
      currentTab = 1;
      newGameName = '';
      displayModal = false;
      submitting = false;

      async beforeRouteEnter(to: any, from: any , next: any) {
        store.commit('pageLoading/setPageLoading', 'Loading gameroom');
        try {
          await store.dispatch('selectedGameroom/updateSelectedGameroom', to.params.id);
          store.commit('pageLoading/setPageLoading', 'Loading games');
          await store.dispatch('games/listGames', to.params.id);
          next();
        } catch (e) {
          store.commit('pageLoading/setPageLoadingComplete');
          if (e.response.status === 404) {
            next({ name: 'not-found' });
          } else if (e.response.status >= 500 || e.response.status < 600) {
            next({ name: 'server-error' });
          } else {
            next({ name: 'request-error' });
          }
        }
      }

      async beforeRouteUpdate(to: any, from: any , next: any) {
        store.commit('pageLoading/setPageLoading', 'Loading gameroom');
        try {
          await store.dispatch('selectedGameroom/updateSelectedGameroom', to.params.id);
          store.commit('pageLoading/setPageLoading', 'Loading games');
          await store.dispatch('games/listGames', to.params.id);
          next();
        } catch (e) {
          store.commit('pageLoading/setPageLoadingComplete');
          if (e.response.status === 404) {
            next({ name: 'not-found' });
          } else if (e.response.status >= 500 || e.response.status < 600) {
            next({ name: 'server-error' });
          } else {
            next({ name: 'request-error' });
          }
        }
      }

      get gameroom(): Gameroom {
         return this.$store.getters['selectedGameroom/getGameroom'];
      }

      get games(): Game[] {
        return this.$store.getters['games/getGames'];
      }

      get gemeroomMembers() {
        if (this.gameroom.members) {
          const organizations = this.gameroom.members.map((member) => member.organization);
          return organizations.join(', ');
        }
      }

     get canSubmitNewGame() {
       if (!this.submitting &&
           this.newGameName !== '') {
         return true;
       }
       return false;
     }

      // intersection of filteredGamesByName and filteredGamesByState
      get filteredGames() {
        const filteredGamesByState = this.filterGamesByState;
        return this.filterGamesByName.filter(
          (game, index, array) => filteredGamesByState.indexOf(game) !== -1);
      }

      get filterGamesByName() {
        return this.games.filter((game, index, array) =>
          game.game_name.toUpperCase().indexOf(this.gameNameFilter.toUpperCase()) > -1);
      }


      get filterGamesByState() {
        const publicKey = this.$store.getters['user/getPublicKey'];
        switch (this.currentTab) {
          case 5:
             return this.games.filter((game, index, array) => gameIsOver(game.game_status));
           case 3:
              return this.games.filter((game, index, array) =>
                !userIsInGame(game, publicKey) && userCanJoinGame(game, publicKey));
           case 2:
              return this.games.filter((game, index, array) =>
                !gameIsOver(game.game_status) && userIsInGame(game, publicKey));
           case 4:
              return this.games.filter((game, index, array) =>
                !gameIsOver(game.game_status)
                && !userIsInGame(game, publicKey)
                && !userCanJoinGame(game, publicKey));
           default:
            return this.games;
        }
    }

    async createGame() {
      if (this.canSubmitNewGame) {
          this.submitting = true;
          try {
             await
              this.$store.dispatch(
                'games/createGame',
                {gameName: this.newGameName, circuitID: this.$route.params.id},
              );

             this.$store.commit(
              'games/setUncommittedGame',
              {gameName: this.newGameName, circuitID: this.$route.params.id},
             );

          } catch (e) {
            console.error(e);
            this.$emit('error', e.message);
          }

          this.submitting = false;
          this.closeNewGameModal();
      }
    }

    selectTab(tab: number) {
      this.currentTab = tab;
    }

    showNewGameModal() {
      this.displayModal = true;
    }

    closeNewGameModal() {
      this.displayModal = false;
      this.newGameName = '';
    }

  }
</script>

<style lang="scss" scoped>
  @import '@/scss/components/_gameroom-details.scss';
</style>
