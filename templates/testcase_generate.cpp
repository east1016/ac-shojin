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

ll myrand(ll l, ll r) { return rand_ll(r - l) + l; }

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    int t;
    t = 1;
    cout << t << endl;
    while (t--) {
        ll a, b, c, d;
        d = myrand(2, 21);
        a = myrand(1, d);
        while (1) {
            b = myrand(0, d);
            c = myrand(0, d);
            if (b < c) break;
        }
        cout << a << ' ' << b << ' ' << c << ' ' << d << endl;
    }
}
