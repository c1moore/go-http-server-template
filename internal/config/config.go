package config

import (
	"encoding/json"

	"github.com/caarlos0/env/v11"
	"github.com/go-playground/validator/v10"
	"github.com/joho/godotenv"
	"github.com/rs/zerolog"
)

type Config struct {
	Server ServerConfig `envPrefix:"SERVER_"`
}

type ServerConfig struct {
	Address string `env:"ADDRESS"`
	Port    int    `env:"PORT" required:"true" validate:"required,gt=0,lt=65536"`

	LogLevel string `env:"LOG_LEVEL" envDefault:"info" validate:"required,oneof=debug info warn error"`

	Env string `env:"ENV" validate:"required,oneof=local dev staging prod"`
}

func LoadConfig(logger zerolog.Logger) (*Config, error) {
	if err := godotenv.Load(); err != nil {
		logger.Warn().Err(err).Msg("failed to load environment variables")
	}

	config := &Config{}
	if err := env.Parse(config); err != nil {
		return nil, err
	}

	if err := validator.New(validator.WithRequiredStructEnabled()).Struct(config); err != nil {
		return nil, err
	}

	return config, nil
}

func (c *Config) LogLevel() zerolog.Level {
	level, err := zerolog.ParseLevel(c.Server.LogLevel)
	if err != nil {
		return zerolog.InfoLevel
	}

	return level
}

func (c *Config) IsProd() bool {
	return c.Server.Env == "prod"
}

func (c *Config) String() string {
	json, _ := json.Marshal(c)

	return string(json)
}
