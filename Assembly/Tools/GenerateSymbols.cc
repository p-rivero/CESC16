#include <iostream>
#include <string>
#include <algorithm>
#include <cassert>

using namespace std;

int main(int argc, char **argv) {
    string label, address;
    char c;

    cout << "#bank program_labels\n\n";
    
    while (cin >> label) {
        assert(cin >> c);
        assert(c == '=');
        assert(cin >> address);
        
        // Count number of dots (depth) of sublabel
        size_t depth = count(label.begin(), label.end(), '.');

        // Hide inner labels
        if (depth > 1) continue;

        string sublabel = label.substr(label.find_last_of(".") + 1);

        // Output result
        cout << "#addr " << address << '\n';
        for (size_t i = 0; i < depth; i++) cout << '.';
        cout << sublabel << ":\n\n";
    }

    cout << "#bank mem" << endl;
}
