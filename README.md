# Tillo.tj — маркетплейс золота, украшений и драгоценных камней

**Демо:** https://bamazaev.github.io/tillo.tj/

Вход в демо: `+992 90 000 00 01`, пароль `tillo123`.
Демо работает без сервера: данные хранятся в браузере.

## Возможности
- Живая цена золота и серебра в сомони (999 / 750 / 585 / 583, серебро 925), курс доллара, обновление каждые 15 минут
- Калькулятор золота: вес × проба × биржевая цена; в каждом объявлении цена сравнивается со стоимостью металла
- 12 категорий: кольца, серьги, цепи, свадебные, часы, слитки и монеты, драгоценные камни, серебро, антиквариат и др.
- Фильтры: металл, проба, камень, состояние, город, цена; сортировка; бесконечная прокрутка
- Регистрация по телефону, подача объявления с фото (до 10), «Мои объявления», избранное, звонок и WhatsApp
- **3 языка:** русский (основной), таджикский, английский
- **Светлая (по умолчанию) и тёмная тема**
- Адаптивный дизайн: телефон, планшет, компьютер

## Технологии
| Часть | Стек |
|---|---|
| `frontend/` | Flutter (Web + Android), BLoC / Cubit, go_router |
| `backend/` | Python, FastAPI, SQLite |

## Запуск
```powershell
.\run.ps1      # собирает сайт и запускает его на http://localhost:8000
```

Вручную:
```powershell
# backend
cd backend
python -m venv .venv; .venv\Scripts\pip install -r requirements-dev.txt
.venv\Scripts\python -m uvicorn app.main:app --reload --port 8000
.venv\Scripts\python -m pytest -q

# frontend (в debug подключается к localhost:8000)
cd frontend
flutter run -d chrome
flutter test
flutter build web --release                     # backend сам раздаёт build/web
flutter build web --dart-define=DEMO=true       # демо без сервера (GitHub Pages)
flutter build web --dart-define=API_URL=https://api.tillo.tj   # другой API
```

Демо-данные для статической версии: `cd backend; .venv\Scripts\python -m tools.export_demo ..\frontend\assets\demo\data.json`

## Переменные окружения backend
| Имя | По умолчанию |
|---|---|
| `TILLO_DATA_DIR` | `backend/data` (база и фото) |
| `TILLO_WEB_DIR` | `frontend/build/web` |
| `TILLO_CORS` | `*` |
| `TILLO_SEED` | `1` — тестовые объявления для пустой базы |
