#pragma GCC target("avx2")
#pragma GCC optimize("O3")
#pragma GCC optimize("unroll-loops")
#include <bits/stdc++.h>

#include <atcoder/all>
#define rep(i, a, b) for (ll i = (ll)(a); i < (ll)(b); i++)
using namespace atcoder;
using namespace std;

typedef long long ll;

static inline long long rand_ll(long long n) {
    static unsigned int tx = 123456789u, ty = 362436069u, tz = 521288629u,
                        tw = 88675123u;
    static bool init = false;
    if (!init) {
        auto seed = (unsigned long long)std::chrono::steady_clock::now()
                        .time_since_epoch()
                        .count();
        tx ^= (unsigned int)(seed);
        ty ^= (unsigned int)(seed >> 16);
        tz ^= (unsigned int)(seed >> 32);
        tw ^= (unsigned int)(seed >> 48);
        init = true;
    }
    unsigned int t = tx ^ (tx << 11);
    tx = ty;
    ty = tz;
    tz = tw;
    unsigned int r = (tw = (tw ^ (tw >> 19)) ^ (t ^ (t >> 8)));
    return (long long)((unsigned long long)r % (unsigned long long)n);
}

void solve() {
    int n = 10;
    dsu uf(n);
    vector<vector<int>> dist(n, vector<int>(n, 1e9));
    while (uf.size(0) < n) {
        int u = rand_ll(n);
        int v = rand_ll(n);
        int x = rand_ll(10) + 1;
        if (u == v) continue;
        if (uf.same(u, v)) continue;
        uf.merge(u, v);
        dist[u][v] = x;
        dist[v][u] = x;
    }
    rep(k, 0, n) {
        rep(i, 0, n) {
            rep(j, 0, n) {
                dist[i][j] = min(dist[i][j], dist[i][k] + dist[k][j]);
            }
        }
    }
    cout << n << endl;
    int ans = 0;
    rep(i, 0, n) rep(j, i + 1, n) ans = max(ans, dist[i][j]);
    while (1) {
        char c;
        cin >> c;
        if (c == '?') {
            int u, v;
            cin >> u >> v;
            u--, v--;
            cout << dist[u][v] << endl;
            fflush(stdout);
        } else {
            int x;
            cin >> x;
            if (x == ans) {
                cout << "Correct!" << endl;
            } else {
                cout << "Wrong Answer!" << endl;
            }
            break;
        }
    }
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    solve();
}
