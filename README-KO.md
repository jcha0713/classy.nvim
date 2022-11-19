# classy.nvim

`classy.nvim`은 HTML / JSX 요소의 클래스 속성 추가와 편집을 도와주는 Neovim 플러그인입니다.

![classy](./extra/classy.gif)

## 어떤 기능이 있나요?

- HTML 요소에서 클래스 속성을 추가하거나 제거할 수 있습니다
- 중첩된 요소 안에서도 동작합니다
- HTML뿐만 아니라 JSX / TSX 문서 안에서도 사용 가능합니다
- 옵션을 통해 작은 따옴표 / 큰 따옴표 설정이 가능합니다
- 트리시터를 활용하여 요소 안 어디서든 동작합니다

## 어떻게 사용하나요?

`classy`는 총 세 개의 함수를 지원합니다: `ClassyAddClass`, `ClassyRemoveClass`, `ClassyResetClass`

이 함수들은 다음과 같이 원하는 키에 바인딩 하여 사용 가능합니다.

```lua
-- 예시입니다:
vim.keymap.set('n', "<leader>ac", :ClassyAddClass<CR>)
vim.keymap.set('n', "<leader>dc", :ClassyRemoveClass<CR>)
vim.keymap.set('n', "<leader>rs", :ClassyResetClass<CR>)
```

### `ClassyAddClass`

커서와 가장 가까운 위치의 요소에 클래스 속성을 찾아 다음 중 한 가지 일을 수행합니다.

- 만약 요소에 클래스 속성이 존재한다면, 커서를 클래스 속성 끝으로 옮겨 바로 편집할 수 있도록 도와줍니다.
- 클래스 속성이 존재하지 않는다면, 새로운 클래스 속성을 자동으로 추가합니다.

```html
<p></p>

<!-- ClassyAddClass -->
<!-- | 는 커서를 의미합니다 -->
<p class="|"></p>
```

```html
<p class="my-p"></p>

<!-- ClassyAddClass -->
<!-- | 는 커서를 의미합니다 -->
<p class="my-p |"></p>
```

### `ClassyRemoveClass`와 `ClassyRestClass`의 차이점

`ClassyRemoveClass`는 요소 내에 존재하는 클래스 속성 자체를 지워줍니다. 반면에 `ClassyResetClass`는 클래스 속성의 값만 지웁니다.

```html
<p class="my-p"></p>

<!-- ClassyRemoveClass -->
<p></p>

<!-- ClassyResetClass -->
<!-- | 는 커서를 의미합니다 -->
<p class="|"></p>
```

## 기본 설정하기

### 플러그인을 설치하기 전에...

- `classy`가 트리시터를 활용해 코드를 파싱하기 위해서 [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)를 필요로 합니다.
- `nvim-treesitter`를 통해 사용할 언어의 파서를 설치해야 합니다.

### 설치 방법

선호하는 플러그인 매니저를 사용하여 간편하게 설치할 수 있습니다. 이 페이지의 예시는 가장 대중적으로 사용되는 [`packer.nvim`](https://github.com/wbthomason/packer.nvim)를 통해 설치하는 방법을 서술하고 있습니다.

```lua
use({
  "jcha0713/classy.nvim",
})
```

## 마무리 설정하기

`init.lua`에 `setup`을 추가해주시면 됩니다. `setup` 함수에게 원하는 옵션값을 넘겨줄 수도 있습니다. 기본 설정에 만족하신다면 안 하셔도 됩니다.

```lua
require('classy').setup({
  -- 기본 설정 값입니다.
  use_double_quote = true,
  insert_after_remove = false,
  move_cursor_after_remove = true,
})
```

### `use_double_quote`

**type**: `boolean`
**default**: `true`

`classy`가 큰 따옴표를 사용할지, 작은 따옴표를 사용할지 선택할 수 있습니다. 기본값으로는 큰 따옴표를 사용하도록 되어 있습니다.

### `insert_after_remove`

**type**: `boolean`
**default**: `false`

`insert_after_remove`가 `true`일 경우에는 클래스 속성을 지울 때 편집에 용이하도록 입력 모드로 전환됩니다. 기본값은 `false`입니다.

### `move_cursor_after_remove`

**type**: `boolean`
**default**: `true`

클래스 속성을 지울 때 커서를 해당 위치로 옮깁니다. 여러 번 중첩된 요소의 종료 태그에서 사용할 때 유용합니다. 기본값은 `true`입니다.

## 프로젝트에 기여하기

PR 또는 issue는 언제든지 환영입니다! 더 깊은 부분을 논의하고 싶다면 [twitter - jcha0713](https://twitter.com/jcha0713)으로 dm 바랍니다.

## 크레딧

`classy`의 아이디어는 우연히 발견한 이 [트윗](https://twitter.com/justinrassier/status/1584632886938173441?s=20&t=kixISG6hBcPfFhXPnJFRqA)으로부터 왔습니다. 감사합니다.
