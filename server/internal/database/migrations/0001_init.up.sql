CREATE TABLE users (
    id            bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          text        NOT NULL,
    email         text        NOT NULL UNIQUE,
    password      text        NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE expenses (
    id          bigint        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     bigint        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name        text          NOT NULL,
    value_cents bigint        NOT NULL,
    date_start                date,
    date_end                  date,
    type        text          NOT NULL DEFAULT 'exit' CHECK (type IN ('exit', 'entry')),
    is_credit   boolean       NOT NULL DEFAULT false,
    created_at  timestamptz   NOT NULL DEFAULT now()
);

CREATE INDEX idx_expenses_user_id ON expenses (user_id);