-- قاعدة بيانات تطبيق ساعة منبّه (SQLite)
PRAGMA foreign_keys = ON;

-- الأصوات المتاحة
CREATE TABLE sounds (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL,
    file_path   TEXT NOT NULL,
    is_custom   INTEGER NOT NULL DEFAULT 0 CHECK (is_custom IN (0, 1))
);

-- المنبّهات
CREATE TABLE alarms (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    label           TEXT,
    hour            INTEGER NOT NULL CHECK (hour BETWEEN 0 AND 23),
    minute          INTEGER NOT NULL CHECK (minute BETWEEN 0 AND 59),
    is_enabled      INTEGER NOT NULL DEFAULT 1 CHECK (is_enabled IN (0, 1)),
    is_repeating    INTEGER NOT NULL DEFAULT 0 CHECK (is_repeating IN (0, 1)),
    one_time_date   TEXT,                       -- YYYY-MM-DD للمنبّه غير المتكرر
    sound_id        INTEGER REFERENCES sounds(id) ON DELETE SET NULL,
    volume          INTEGER NOT NULL DEFAULT 80 CHECK (volume BETWEEN 0 AND 100),
    vibrate         INTEGER NOT NULL DEFAULT 1 CHECK (vibrate IN (0, 1)),
    gradual_volume  INTEGER NOT NULL DEFAULT 0 CHECK (gradual_volume IN (0, 1)),
    snooze_minutes  INTEGER NOT NULL DEFAULT 5,
    snooze_limit    INTEGER NOT NULL DEFAULT 3, -- أقصى عدد مرات الغفوة
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- أيام التكرار (0 = الأحد ... 6 = السبت)
CREATE TABLE alarm_repeat_days (
    alarm_id    INTEGER NOT NULL REFERENCES alarms(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    PRIMARY KEY (alarm_id, day_of_week)
);

-- سجل الرنين والإجراءات
CREATE TABLE alarm_history (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    alarm_id      INTEGER REFERENCES alarms(id) ON DELETE SET NULL,
    rang_at       TEXT NOT NULL DEFAULT (datetime('now')),
    action        TEXT NOT NULL CHECK (action IN ('dismissed', 'snoozed', 'missed')),
    snooze_count  INTEGER NOT NULL DEFAULT 0,
    response_secs INTEGER                         -- الزمن حتى استجابة المستخدم
);

-- الإعدادات العامة
CREATE TABLE settings (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

-- فهارس
CREATE INDEX idx_alarms_enabled ON alarms (is_enabled, hour, minute);
CREATE INDEX idx_history_alarm  ON alarm_history (alarm_id, rang_at);

-- تحديث وقت التعديل تلقائيًا
CREATE TRIGGER trg_alarms_updated
AFTER UPDATE ON alarms
FOR EACH ROW
BEGIN
    UPDATE alarms SET updated_at = datetime('now') WHERE id = OLD.id;
END;

-- بيانات أولية
INSERT INTO sounds (name, file_path) VALUES
    ('Morning', 'sounds/morning.mp3'),
    ('Classic', 'sounds/classic.mp3'),
    ('Gentle',  'sounds/gentle.mp3');

INSERT INTO settings (key, value) VALUES
    ('time_format', '24h'),
    ('week_start',  'saturday'),
    ('silent_mode_override', '1');

-- مثال: منبّه الساعة 6:30 صباحًا من الأحد إلى الخميس
INSERT INTO alarms (label, hour, minute, is_repeating, sound_id)
VALUES ('الاستيقاظ', 6, 30, 1, 1);
INSERT INTO alarm_repeat_days (alarm_id, day_of_week)
VALUES (1, 0), (1, 1), (1, 2), (1, 3), (1, 4);
