/* ==========================================================================
   FFMS Store — talks to the real PHP + MySQL backend via api.js.
   Kept the same Store / Auth shape the rest of the app already uses, so
   call sites mostly just needed `await` added, not a rewrite.
   ========================================================================== */
import { Api, ApiError, getStoredUser, getToken, setSession, clearSession, getSelectedFarm, setSelectedFarm } from './api.js';
export { getSelectedFarm, setSelectedFarm };

export const ROLES = [
  { id: 'admin',      label: 'Administrator', blurb: 'Full system & user access' },
  { id: 'owner',      label: 'Farm Owner',    blurb: 'Owns and oversees farms'   },
  { id: 'manager',    label: 'Farm Manager',  blurb: 'Runs day-to-day operations' },
  { id: 'agronomist', label: 'Agronomist',    blurb: 'Crops, soil & field health' },
  { id: 'accountant', label: 'Accountant',    blurb: 'Finance & sales records'   },
  { id: 'worker',     label: 'Worker',        blurb: 'Field & task execution'    },
];

function roleLabel(id){
  const r = ROLES.find(r => r.id === id);
  return r ? r.label : id;
}

export const Store = {
  all: (entity) => Api.list(entity),
  get: (entity, id) => Api.get(entity, id),
  insert: (entity, record) => Api.create(entity, record),
  update: (entity, id, patch) => Api.update(entity, id, patch),
  remove: (entity, id) => Api.remove(entity, id),
  count: async (entity) => (await Api.list(entity)).length,
};

export const Auth = {
  roleLabel,

  /** Cached user from the last successful login/verify — synchronous, may be stale. Use verifySession() to confirm. */
  cachedUser(){ return getStoredUser(); },

  async signup({ firstName, lastName, email, password, role, phone }){
    return Api.signup({ firstName, lastName, email, password, role, phone });
  },

  async verifyEmail(token){
    return Api.verifyEmail(token);
  },

  async resendVerification(email){
    return Api.resendVerification(email);
  },

  async login(email, password){
    const result = await Api.login(email, password);
    setSession(result.token, result.user);
    return result.user;
  },

  async forgotPassword(email){
    return Api.forgotPassword(email);
  },

  async resetPassword(token, password){
    return Api.resetPassword(token, password);
  },

  async changePassword(currentPassword, newPassword){
    return Api.changePassword(currentPassword, newPassword);
  },

  /** Confirms the cached session is still valid against the server; clears it if not. */
  async verifySession(){
    try{
      const user = await Api.me();
      setSession(getToken(), user);
      return user;
    }catch(e){
      if (e instanceof ApiError && (e.status === 401 || e.status === 403)){
        clearSession();
      }
      return null;
    }
  },

  async signOut(){
    try{ await Api.logout(); }catch(e){ /* token may already be invalid — fine, we're clearing it anyway */ }
    clearSession();
  },

  listUsers: () => Api.team(),
  updateUser: (id, patch) => Api.updateTeamMember(id, patch),

  /** Redirects to login.html if there's no valid session; otherwise resolves with the user. */
  async requireSession(){
    const user = await Auth.verifySession();
    if (!user){ window.location.href = 'login.html'; return null; }
    return user;
  },
};

export { ApiError };

export const Audit = {
  list: () => Api.auditLog(),
};

