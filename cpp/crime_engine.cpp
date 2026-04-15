// Crime engine: k-means risk clustering + logistic arrest classifier.
// Build: make -C .  (see Makefile)

#include <algorithm>
#include <cmath>
#include <fstream>
#include <iostream>
#include <numeric>
#include <random>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace {

struct Row {
    double lat{};
    double lon{};
    double hour{};
    double night{};
    double weekend{};
    double domestic{};
    int arrest{};
    int density{1};
};

std::vector<std::string> split_csv(const std::string& line) {
    std::vector<std::string> out;
    std::string cur;
    bool in_quotes = false;
    for (char c : line) {
        if (c == '"') {
            in_quotes = !in_quotes;
        } else if (c == ',' && !in_quotes) {
            out.push_back(cur);
            cur.clear();
        } else {
            cur.push_back(c);
        }
    }
    out.push_back(cur);
    return out;
}

double to_d(const std::string& s) {
    try {
        return std::stod(s);
    } catch (...) {
        return 0.0;
    }
}

int to_i(const std::string& s) {
    try {
        return std::stoi(s);
    } catch (...) {
        return 0;
    }
}

std::vector<Row> load_csv(const std::string& path) {
    std::ifstream in(path);
    if (!in) {
        throw std::runtime_error("cannot open " + path);
    }
    std::string header;
    std::getline(in, header);
    auto cols = split_csv(header);
    auto idx = [&](const std::string& name) -> int {
        for (size_t i = 0; i < cols.size(); ++i) {
            std::string c = cols[i];
            if (!c.empty() && c.front() == '"') c = c.substr(1, c.size() - 2);
            if (c == name) return static_cast<int>(i);
        }
        return -1;
    };
    const int i_lat = idx("Latitude");
    const int i_lon = idx("Longitude");
    const int i_hour = idx("Hour");
    const int i_night = idx("Night");
    const int i_week = idx("Weekend");
    const int i_dom = idx("Domestic");
    const int i_arr = idx("Arrest");
    if (i_lat < 0 || i_lon < 0 || i_hour < 0 || i_night < 0) {
        throw std::runtime_error("CSV missing Latitude/Longitude/Hour/Night");
    }

    std::vector<Row> rows;
    std::string line;
    while (std::getline(in, line)) {
        if (line.empty()) continue;
        auto f = split_csv(line);
        auto get = [&](int i) -> std::string {
            if (i < 0 || i >= static_cast<int>(f.size())) return "0";
            return f[static_cast<size_t>(i)];
        };
        Row r;
        r.lat = to_d(get(i_lat));
        r.lon = to_d(get(i_lon));
        r.hour = to_d(get(i_hour));
        r.night = to_d(get(i_night));
        r.weekend = i_week >= 0 ? to_d(get(i_week)) : 0;
        r.domestic = i_dom >= 0 ? to_d(get(i_dom)) : 0;
        r.arrest = i_arr >= 0 ? to_i(get(i_arr)) : 0;
        rows.push_back(r);
    }
    return rows;
}

void attach_density(std::vector<Row>& rows) {
    std::unordered_map<long long, int> counts;
    auto key = [](const Row& r) -> long long {
        long long a = static_cast<long long>(std::llround(r.lat * 1000.0));
        long long b = static_cast<long long>(std::llround(r.lon * 1000.0));
        return (a << 32) ^ (b & 0xffffffffLL);
    };
    for (const auto& r : rows) counts[key(r)]++;
    for (auto& r : rows) r.density = counts[key(r)];
}

struct Stats {
    std::vector<double> mean;
    std::vector<double> sd;
};

Stats zscore_fit(const std::vector<std::vector<double>>& x) {
    const size_t n = x.size();
    const size_t d = x[0].size();
    Stats s;
    s.mean.assign(d, 0.0);
    s.sd.assign(d, 0.0);
    for (const auto& row : x) {
        for (size_t j = 0; j < d; ++j) s.mean[j] += row[j];
    }
    for (size_t j = 0; j < d; ++j) s.mean[j] /= static_cast<double>(n);
    for (const auto& row : x) {
        for (size_t j = 0; j < d; ++j) {
            double v = row[j] - s.mean[j];
            s.sd[j] += v * v;
        }
    }
    for (size_t j = 0; j < d; ++j) {
        s.sd[j] = std::sqrt(s.sd[j] / static_cast<double>(n));
        if (s.sd[j] < 1e-12) s.sd[j] = 1.0;
    }
    return s;
}

std::vector<std::vector<double>> zscore_apply(const std::vector<std::vector<double>>& x, const Stats& s) {
    std::vector<std::vector<double>> out = x;
    for (auto& row : out) {
        for (size_t j = 0; j < row.size(); ++j) {
            row[j] = (row[j] - s.mean[j]) / s.sd[j];
        }
    }
    return out;
}

double dist2(const std::vector<double>& a, const std::vector<double>& b) {
    double s = 0;
    for (size_t i = 0; i < a.size(); ++i) {
        double d = a[i] - b[i];
        s += d * d;
    }
    return s;
}

std::pair<std::vector<int>, double> kmeans(const std::vector<std::vector<double>>& x, int k, int seed) {
    const size_t n = x.size();
    const size_t d = x[0].size();
    std::mt19937 rng(seed);
    std::uniform_int_distribution<size_t> pick(0, n - 1);

    std::vector<std::vector<double>> c(static_cast<size_t>(k), std::vector<double>(d));
    for (int i = 0; i < k; ++i) c[static_cast<size_t>(i)] = x[pick(rng)];

    std::vector<int> label(n, 0);
    for (int iter = 0; iter < 40; ++iter) {
        bool changed = false;
        for (size_t i = 0; i < n; ++i) {
            int best = 0;
            double best_d = dist2(x[i], c[0]);
            for (int j = 1; j < k; ++j) {
                double dd = dist2(x[i], c[static_cast<size_t>(j)]);
                if (dd < best_d) {
                    best_d = dd;
                    best = j;
                }
            }
            if (label[i] != best) {
                label[i] = best;
                changed = true;
            }
        }
        std::vector<std::vector<double>> sum(static_cast<size_t>(k), std::vector<double>(d, 0.0));
        std::vector<int> cnt(static_cast<size_t>(k), 0);
        for (size_t i = 0; i < n; ++i) {
            int lab = label[i];
            cnt[static_cast<size_t>(lab)]++;
            for (size_t j = 0; j < d; ++j) sum[static_cast<size_t>(lab)][j] += x[i][j];
        }
        for (int j = 0; j < k; ++j) {
            if (cnt[static_cast<size_t>(j)] == 0) {
                c[static_cast<size_t>(j)] = x[pick(rng)];
                continue;
            }
            for (size_t t = 0; t < d; ++t) {
                c[static_cast<size_t>(j)][t] = sum[static_cast<size_t>(j)][t] / cnt[static_cast<size_t>(j)];
            }
        }
        if (!changed) break;
    }

    double sse = 0;
    for (size_t i = 0; i < n; ++i) sse += dist2(x[i], c[static_cast<size_t>(label[i])]);
    return {label, sse};
}

double sigmoid(double z) {
    z = std::max(-30.0, std::min(30.0, z));
    return 1.0 / (1.0 + std::exp(-z));
}

std::vector<double> logistic_fit(const std::vector<std::vector<double>>& x, const std::vector<int>& y, int steps) {
    const size_t n = x.size();
    const size_t d = x[0].size();
    std::vector<double> w(d + 1, 0.0);
    const double lr = 0.15;
    for (int s = 0; s < steps; ++s) {
        std::vector<double> g(d + 1, 0.0);
        for (size_t i = 0; i < n; ++i) {
            double z = w[0];
            for (size_t j = 0; j < d; ++j) z += w[j + 1] * x[i][j];
            double p = sigmoid(z);
            double err = p - static_cast<double>(y[i]);
            g[0] += err;
            for (size_t j = 0; j < d; ++j) g[j + 1] += err * x[i][j];
        }
        for (size_t j = 0; j < w.size(); ++j) w[j] -= lr * g[j] / static_cast<double>(n);
    }
    return w;
}

double logistic_acc(const std::vector<std::vector<double>>& x, const std::vector<int>& y, const std::vector<double>& w) {
    size_t ok = 0;
    for (size_t i = 0; i < x.size(); ++i) {
        double z = w[0];
        for (size_t j = 0; j < x[i].size(); ++j) z += w[j + 1] * x[i][j];
        int pred = sigmoid(z) >= 0.5 ? 1 : 0;
        if (pred == y[i]) ok++;
    }
    return static_cast<double>(ok) / static_cast<double>(x.size());
}

void cmd_cluster(const std::string& in_path, const std::string& out_path) {
    auto rows = load_csv(in_path);
    if (rows.empty()) throw std::runtime_error("no rows");
    attach_density(rows);

    std::vector<std::vector<double>> x;
    x.reserve(rows.size());
    for (const auto& r : rows) {
        x.push_back({r.lat, r.lon, r.hour, r.night, static_cast<double>(r.density)});
    }
    auto stats = zscore_fit(x);
    auto xs = zscore_apply(x, stats);

    std::vector<int> best_lab;
    double best_sse = 1e300;
    for (int seed : {123, 7, 99, 2026}) {
        auto [lab, sse] = kmeans(xs, 4, seed);
        if (sse < best_sse) {
            best_sse = sse;
            best_lab = std::move(lab);
        }
    }

    std::ifstream in(in_path);
    std::ofstream out(out_path);
    std::string header;
    std::getline(in, header);
    out << header << ",Cluster\n";
    std::string line;
    size_t i = 0;
    while (std::getline(in, line) && i < best_lab.size()) {
        if (line.empty()) continue;
        out << line << "," << (best_lab[i] + 1) << "\n";
        ++i;
    }
    std::cerr << "clustered " << i << " rows, k=4, sse=" << best_sse << "\n";
}

void cmd_classify(const std::string& in_path) {
    auto rows = load_csv(in_path);
    std::vector<std::vector<double>> x;
    std::vector<int> y;
    for (const auto& r : rows) {
        x.push_back({r.hour, r.night, r.weekend, r.domestic});
        y.push_back(r.arrest);
    }
    auto stats = zscore_fit(x);
    auto xs = zscore_apply(x, stats);
    auto w = logistic_fit(xs, y, 80);
    double acc = logistic_acc(xs, y, w);
    std::cout << "arrest_logistic_accuracy " << acc << "\n";
    std::cout << "weights bias=" << w[0] << " hour=" << w[1] << " night=" << w[2]
              << " weekend=" << w[3] << " domestic=" << w[4] << "\n";
}

}  // namespace

int main(int argc, char** argv) {
    try {
        if (argc < 3) {
            std::cerr << "usage:\n  crime_engine cluster <in.csv> <out.csv>\n"
                         "  crime_engine classify <in.csv>\n";
            return 2;
        }
        std::string cmd = argv[1];
        if (cmd == "cluster") {
            if (argc < 4) return 2;
            cmd_cluster(argv[2], argv[3]);
            return 0;
        }
        if (cmd == "classify") {
            cmd_classify(argv[2]);
            return 0;
        }
        std::cerr << "unknown command " << cmd << "\n";
        return 2;
    } catch (const std::exception& ex) {
        std::cerr << "error: " << ex.what() << "\n";
        return 1;
    }
}
