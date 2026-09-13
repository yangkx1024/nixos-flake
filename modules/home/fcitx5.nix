{config, ...}: {
  # fcitx5 grabs Shift_L by default ("temporarily switch to the first input
  # method"), so Rime never sees the key. Clear it and let Rime's ascii_composer
  # own Shift instead. An empty section is not enough here - fcitx5 falls back to
  # the built-in default unless the list has an explicit empty entry.
  #
  # fcitx5 reads the first config file it finds rather than merging, so these
  # user-level files fully shadow anything in /etc/xdg - which is why they live
  # here and not in i18n.inputMethod.fcitx5.settings. The trade is that
  # fcitx5-configtool can no longer save: it writes its own copy over the store
  # symlink, and the next rebuild moves that aside as *.backup. Edit these
  # settings here, not in the GUI.
  xdg.configFile."fcitx5/config".text = ''
    [Hotkey/AltTriggerKeys]
    0=
  '';

  # 候选栏外观。只列真正要改的四项，其余留空回落到 fcitx5 的内置默认
  # （见 src/ui/classic/classicui.h）。
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    # 竖排候选列表
    Vertical Candidate List=True
    # 候选栏字体，与 gtk/qt 的 MiSans 10 保持一致
    Font="MiSans 10"
    # 主题由 noctalia 的 fcitx5 社区模板渲染到
    # ~/.local/share/fcitx5/themes/noctalia/。模板只渲染当前明暗模式的配色，
    # 所以不需要 DarkTheme（UseDarkTheme 默认关闭，本来也不会用到它）。
    # 模板的 apply 钩子发现这里已是 noctalia 就不会去写这个只读文件，
    # 只通过 D-Bus 让 classicui 重载配色。
    Theme=noctalia
  '';

  # Rime user directory for fcitx5. The schemas and dictionaries themselves come
  # from the rime-ice data baked into fcitx5-rime (see modules/core/fcitx5.nix);
  # only this patch lives here. Everything else in ~/.local/share/fcitx5/rime
  # (build cache, learned words) stays mutable.
  xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
    text = ''
      # 由 NixOS flake 管理，改动请编辑 modules/home/fcitx5.nix
      patch:
        # 雾凇拼音上游的 default.yaml，nixpkgs 把它改名成了 rime_ice_suggestion.yaml
        __include: rime_ice_suggestion:/

        # 只启用全拼，按需取消注释想用的双拼方案
        schema_list:
          - schema: rime_ice
          # - schema: t9
          # - schema: double_pinyin
          # - schema: double_pinyin_abc
          # - schema: double_pinyin_mspy
          # - schema: double_pinyin_sogou
          # - schema: double_pinyin_flypy
          # - schema: double_pinyin_ziguang
          # - schema: double_pinyin_jiajia

        # 候选词个数
        menu/page_size: 8

        # 左右 Shift 都上屏已输入的原始字母，然后切到英文
        # commit_code 上屏编码 | commit_text 上屏候选词 | clear 清空 | noop 不处理
        ascii_composer/switch_key/Shift_L: commit_code
        ascii_composer/switch_key/Shift_R: commit_code

        # Tab / Shift+Tab 选择下/上一个候选项（Down/Up 交给 selector，会自动翻页）。
        #
        # 必须写成 key_binder: 下嵌套 bindings/+ 的形式。平铺成
        # key_binder/bindings/+ 不行：PatchLiteral 那时 __include 还没落地，
        # EditNode 见 target 为空就走覆盖分支，整份 bindings 会被这两条顶掉。
        #
        # 用 /+ 追加，而不是按下标覆盖上游那两条同键绑定：key_binder 把同一个键的
        # 绑定按条件排序后取第一个命中的，而 has_menu 排在 composing 前面
        # （key_binder.cc 的 KeyBindingCondition 枚举 + KeyBinding::operator<），
        # 所以只要有候选菜单，这两条一定压过上游的 composing 绑定，与列表位置无关。
        # 上游那两条也就得以保留，在“正在输入但没有候选”时继续移动音节光标。
        #
        # 注意 Shift+Tab 的 keysym 是 ISO_Left_Tab 而不是 Tab，fcitx5 传给 rime 的
        # 是未规范化的原始 keysym（rimestate.cpp 用的是 event.rawKey().sym()），
        # 写成 Shift+Tab 不会匹配，键会被透传给应用，表现为焦点跳走、输入被打断。
        key_binder:
          bindings/+:
            - {when: has_menu, accept: Tab, send: Down}
            - {when: has_menu, accept: Shift+ISO_Left_Tab, send: Up}
    '';

    # Rime only recompiles when a source file's recorded mtime differs from the
    # file's own (deployment_tasks.cc, ConfigNeedsUpdate). Every file under
    # /nix/store has mtime 1, so that check never trips and Rime silently keeps
    # serving a stale build/ - edits above would never take effect. Dropping the
    # compiled config forces a rebuild on the next fcitx5 start. The .bin
    # dictionaries are keyed on content, so they survive and this costs ~5s
    # rather than the ~15s a full build/ wipe would. The patch is merged into
    # every compiled schema, not just default.yaml, hence the glob.
    onChange = ''
      rm -f ${config.xdg.dataHome}/fcitx5/rime/build/default.yaml \
            ${config.xdg.dataHome}/fcitx5/rime/build/*.schema.yaml
    '';
  };
}
