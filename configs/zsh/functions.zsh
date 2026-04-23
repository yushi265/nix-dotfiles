# repo: ghq repository/worktree selector with fzf
repo() {
    local selected current_git_common ghq_root
    current_git_common=$(git rev-parse --git-common-dir 2>/dev/null | xargs -I{} realpath {} 2>/dev/null)
    ghq_root=$(ghq root)

    selected=$(ghq list --full-path 2>/dev/null | \
        while read -r repo_path; do
            local git_common is_first wt_path wt_name rel_path
            git_common=$(realpath "$repo_path/.git" 2>/dev/null)
            rel_path=$(echo "$repo_path" | sed "s|^$ghq_root/||")
            is_first=true
            while IFS= read -r line; do
                case "$line" in
                    worktree\ *)
                        wt_path=$(echo "$line" | sed 's/^worktree //')
                        wt_name=$(basename "$wt_path")
                        if $is_first; then
                            printf '%s\t0\t%s\t\033[32m%s\033[0m\n' "$git_common" "$wt_path" "$rel_path"
                            is_first=false
                        else
                            printf '%s\t1\t%s\t\033[33m↳ %s\033[0m\n' "$git_common" "$wt_path" "$wt_name"
                        fi
                        ;;
                esac
            done < <(git -C "$repo_path" worktree list --porcelain 2>/dev/null)
        done | \
        awk -F'\t' -v cur="$current_git_common" '{
            if ($1 == cur) print "0\t" $0
            else print "1\t" $0
        }' | \
        sort -t$'\t' -k1,1 -k2,2 -k3,3n -k5 | \
        cut -f4- | \
        fzf --ansi --height 40% --reverse --delimiter=$'\t' --with-nth=2 --preview 'ls -la {1}' --query "$1" | \
        cut -f1)

    if [[ -n "$selected" ]]; then
        cd "$selected" || return 1
    fi
}

# gd: interactive git diff with fzf
gd() {
    emulate -L zsh
    setopt NO_XTRACE NO_VERBOSE

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Error: Not a git repository" >&2
        return 1
    fi

    local mode files result key selected preview_cmd reload_cmd
    mode="all"

    while getopts "suh" opt; do
        case $opt in
            s) mode="staged" ;;
            u) mode="unstaged" ;;
            h)
                echo "Usage: gd [-s|-u|-h]"
                echo "  -s  Show staged changes only"
                echo "  -u  Show unstaged changes only"
                echo "  -h  Show this help"
                echo ""
                echo "Keys:"
                echo "  ENTER    View diff (delta)"
                echo "  CTRL-E   Edit file in vim"
                echo "  CTRL-S   Toggle stage/unstage"
                echo "  ESC      Quit"
                return 0
                ;;
            *) return 1 ;;
        esac
    done

    preview_cmd='echo {1} | grep -q S && git diff --cached --color=always -- {2} | delta || git diff --color=always -- {2} | delta'
    reload_cmd='git diff --cached --name-only | while read -r f; do [ -n "$f" ] && printf "\033[32m[S]\033[0m %s\n" "$f"; done; git diff --name-only | while read -r f; do [ -n "$f" ] && printf "\033[33m[U]\033[0m %s\n" "$f"; done'

    while true; do
        case $mode in
            staged) files=$(git diff --cached --name-only | sed 's/^/[S] /') ;;
            unstaged) files=$(git diff --name-only | sed 's/^/[U] /') ;;
            all)
                files=$(
                    git diff --cached --name-only | while read -r f; do
                        [[ -n "$f" ]] && printf '\033[32m[S]\033[0m %s\n' "$f"
                    done
                    git diff --name-only | while read -r f; do
                        [[ -n "$f" ]] && printf '\033[33m[U]\033[0m %s\n' "$f"
                    done
                )
                ;;
        esac

        if [[ -z "$files" ]]; then
            echo "No changes found"
            break
        fi

        result=$(echo "$files" | fzf \
            --ansi --height 60% --reverse --delimiter=' ' --expect=ctrl-e \
            --preview "$preview_cmd" --preview-window 'right:60%:wrap' \
            --header 'ENTER: diff | CTRL-E: edit | CTRL-S: stage/unstage | ESC: quit' \
            --bind "ctrl-s:execute-silent(echo {1} | grep -q S && git reset HEAD -- {2} || git add -- {2})+reload($reload_cmd)")

        [[ -z "$result" ]] && break

        key=$(echo "$result" | head -1)
        selected=$(echo "$result" | tail -1 | sed 's/^\[[SU]\] //')

        [[ -z "$selected" ]] && break

        case $key in
            ctrl-e) nvim "$selected" ;;
            *)
                if git diff --cached --name-only | grep -qx "$selected"; then
                    git diff --cached -- "$selected" | delta --paging=never | less -R
                else
                    git diff -- "$selected" | delta --paging=never | less -R
                fi
                ;;
        esac
    done
}

# rgf: interactive ripgrep with fzf
rgf() {
    local initial_query="${*:-}"
    local result file line

    result=$(rg --color=always --line-number --no-heading . 2>/dev/null | \
        fzf --ansi --disabled --query "$initial_query" \
            --bind "change:reload:rg --color=always --line-number --no-heading {q} || true" \
            --delimiter=: \
            --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
            --preview-window 'right:60%:+{2}-5')

    if [[ -n "$result" ]]; then
        file=$(echo "$result" | cut -d: -f1)
        line=$(echo "$result" | cut -d: -f2)
        nvim "+$line" "$file"
    fi
}
