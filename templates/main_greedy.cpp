#pragma GCC target("avx2")
#pragma GCC optimize("O3")
#pragma GCC optimize("unroll-loops")
#include <bits/stdc++.h>

#include <atcoder/all>
#define rep(i, a, b) for (ll i = (ll)(a); i < (ll)(b); i++)
using namespace atcoder;
using namespace std;

typedef long long ll;

template <typename T>
T ceil_div(T a, T b) {
    if (b < 0) a = -a, b = -b;
    return (a >= 0 ? (a + b - 1) / b : a / b);
}

template <typename T>
T floor_div(T a, T b) {
    if (b < 0) a = -a, b = -b;
    return (a >= 0 ? a / b : (a - b + 1) / b);
}

void solve() {
    ll a, b, c, d;
    cin >> a >> b >> c >> d;
    int ans = 0;
    rep(i, 1, 100) {
        ll l = a + b * i;
        ll r = a + c * i;
        if (ceil_div(l, d) > floor_div(r, d)) ans++;
    }
    cout << ans << endl;
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
    cout << fixed << setprecision(15);
    int t;
    cin >> t;
    while (t--) solve();
}
