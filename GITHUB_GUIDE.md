# Руководство по использованию GitHub для Slashers Server

## Быстрый старт

### Проверка статуса
```bash
git status
```
Показывает файлы с изменениями (красный = изменён, зелёный = новый).

### Индексация и коммит
```bash
git add <файл>          # добавить один файл
git add .               # добавить все изменённые файлы
git commit -m "Сообщение"
```

### Отправка на GitHub
```bash
git push origin main
```

---

## Типичный рабочий цикл

### 1. В начале сессии — подтянуть свежие изменения
```bash
git pull origin main
```

### 2. Поработал, сделал изменения → закоммитить
```bash
git add <изменённые файлы>
git commit -m "Краткое описание что сделано"
```

### 3. В конце сессии — запушить
```bash
git push origin main
```

---

## Просмотр истории

```bash
git log --oneline            # компактный список коммитов
git log --oneline -5         # последние 5
git diff                     # что изменилось с последнего коммита
git diff <файл>             # изменения в конкретном файле
```

---

## Отмена изменений

```bash
# Отменить изменения в файле (до последнего коммита)
git checkout -- <файл>

# Отменить коммит (сохраняя изменения в файлах)
git reset --soft HEAD~1

# Полностью удалить последний коммит
git reset --hard HEAD~1
```

---

## Ветки (если понадобятся)

```bash
git branch                          # список веток
git checkout -b новая-ветка          # создать и переключиться
git checkout main                   # вернуться на main
git merge новая-ветка                # слить ветку в main
git branch -d новая-ветка            # удалить ветку
```

---

## Git на этом проекте

Git установлен здесь:
```
C:\Program Files\Git\cmd\git.exe
```

Команды вызываются с полным путём:
```bash
"C:\Program Files\Git\cmd\git.exe" -C "путь\к\проекту" <команда>
```

Или добавить в PATH (один раз):
```bash
setx PATH "%PATH%;C:\Program Files\Git\cmd"
```

---

## Удалённый репозиторий

Проект привязан к:
```
https://github.com/korutchakn-arch/slashers-dev.git
```

**Важно:** пушить только в ветку `main`. Не создавать pull requests внутри — пушить напрямую.

---

## Частые ошибки

| Ошибка | Причина | Решение |
|---|---|---|
| `git is not recognized` | Git не в PATH | Использовать полный путь или добавить в PATH |
| `src refspec main does not match` | Не на той ветке | `git checkout main` сначала |
| `nothing to commit` | Нет изменений | Всё уже закоммичено |
| `failed to push some refs` | Удалённый опережает локальный | `git pull origin main` → `git push` |

---

## Для автора (fallE)

- **Репозиторий:** https://github.com/korutchakn-arch/slashers-dev
- **Клонировать проект на новую машину:**
  ```bash
  git clone https://github.com/korutchakn-arch/slashers-dev.git "Slashers-master"
  ```
