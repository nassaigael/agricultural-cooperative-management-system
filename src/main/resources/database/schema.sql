CREATE TABLE IF NOT EXISTS federation
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL UNIQUE,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE federation IS 'Fédérations regroupant les collectivités';

CREATE TABLE IF NOT EXISTS account
(
    id           SERIAL PRIMARY KEY,
    username     VARCHAR(255) NOT NULL UNIQUE,
    email        VARCHAR(255) UNIQUE,
    phone_number VARCHAR(255),
    account_type VARCHAR(50)  NOT NULL,

    created_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS collectivity
(
    id                     SERIAL PRIMARY KEY,
    name                   VARCHAR(255) NOT NULL UNIQUE,
    city                   VARCHAR(255) NOT NULL,
    agricultural_specialty VARCHAR(255) NOT NULL,
    registration_number    INTEGER      NOT NULL UNIQUE,
    creation_date          DATE         NOT NULL,

    federation_id          INTEGER      REFERENCES federation (id) ON DELETE SET NULL,

    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS member
(
    id           SERIAL PRIMARY KEY,
    last_name    VARCHAR(255)   NOT NULL,
    first_name   VARCHAR(255)   NOT NULL,
    birth_date   DATE           NOT NULL,
    gender       SMALLINT       NOT NULL CHECK (gender IN (0, 1, 2)),
    phone_number VARCHAR(255)   NOT NULL,
    email        VARCHAR(255),
    join_date    DATE           NOT NULL DEFAULT CURRENT_DATE,

    account_id   INTEGER UNIQUE REFERENCES account (id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS role
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mandate
(
    id         SERIAL PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date   DATE NOT NULL CHECK (end_date > start_date),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS membership
(
    id              SERIAL PRIMARY KEY,
    member_id       INTEGER NOT NULL REFERENCES member (id) ON DELETE CASCADE,
    collectivity_id INTEGER NOT NULL REFERENCES collectivity (id) ON DELETE CASCADE,

    joined_at       DATE DEFAULT CURRENT_DATE,

    UNIQUE (member_id, collectivity_id)
);

CREATE TABLE IF NOT EXISTS assignment
(
    id              SERIAL PRIMARY KEY,

    member_id       INTEGER NOT NULL REFERENCES member (id) ON DELETE CASCADE,
    role_id         INTEGER NOT NULL REFERENCES role (id) ON DELETE RESTRICT,
    mandate_id      INTEGER NOT NULL REFERENCES mandate (id) ON DELETE RESTRICT,

    collectivity_id INTEGER REFERENCES collectivity (id) ON DELETE CASCADE,
    federation_id   INTEGER REFERENCES federation (id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contribution
(
    id              SERIAL PRIMARY KEY,
    collectivity_id INTEGER        NOT NULL REFERENCES collectivity (id) ON DELETE CASCADE,
    year            INTEGER        NOT NULL,
    amount          DECIMAL(12, 2) NOT NULL,
    due_date        DATE           NOT NULL,
    UNIQUE (collectivity_id, year)
);

CREATE TABLE IF NOT EXISTS payment
(
    id                    SERIAL PRIMARY KEY,
    payment_date          DATE           NOT NULL DEFAULT CURRENT_DATE,
    amount_paid           DECIMAL(12, 2) NOT NULL,
    payment_method        SMALLINT       NOT NULL,
    status                VARCHAR(20)             DEFAULT 'SUCCESS' CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELLED')),
    member_id             INTEGER        NOT NULL REFERENCES member (id) ON DELETE RESTRICT,
    contribution_id       INTEGER        NOT NULL REFERENCES contribution (id) ON DELETE RESTRICT,
    paid_by_account_id    INTEGER        REFERENCES account (id) ON DELETE SET NULL,
    transaction_reference VARCHAR(255),
    note                  TEXT,
    created_at            TIMESTAMPTZ             DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_member_email ON member (email);
CREATE INDEX IF NOT EXISTS idx_collectivity_city ON collectivity (city);
CREATE INDEX IF NOT EXISTS idx_assignment_member ON assignment (member_id);
CREATE INDEX IF NOT EXISTS idx_assignment_role ON assignment (role_id);
CREATE INDEX IF NOT EXISTS idx_payment_contribution ON payment (contribution_id);
CREATE INDEX IF NOT EXISTS idx_membership_collectivity ON membership (collectivity_id);