package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/c1moore/go-http-server-template/internal/config"
	"github.com/c1moore/go-http-server-template/internal/health"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/hlog"
)

var version string

func main() {
	logger := zerolog.New(os.Stderr).With().Timestamp().Logger().With().Str("version", version).Logger()

	config, err := config.LoadConfig(logger)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to load config")
	}

	logger = logger.Level(config.LogLevel())
	logger.Info().Interface("config", config).Msg("config loaded")

	if config.IsProd() {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(gin.WrapH(hlog.NewHandler(logger)(nil)))

	health.InitRoutes(router.Group("/health"))

	srv := &http.Server{
		Addr:    fmt.Sprintf("%s:%d", config.Server.Address, config.Server.Port),
		Handler: router.Handler(),
	}

	go func() {
		logger.Info().Int("port", config.Server.Port).Msg("server started")

		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal().Err(err).Msg("failed to start server")
		} else {
			logger.Info().Msg("server stopped")
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info().Msg("shutting down server")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Fatal().Err(err).Msg("failed to shutdown server")
	}
}
