package main

import (
	"context"
	"encoding/json"
	"log"
	"time"
)

type AnalyticsEventPublisher interface {
	Publish(ctx context.Context, content string) error
}

type EvaluationEvent struct {
	UserID    string    `json:"user_id"`
	FlagName  string    `json:"flag_name"`
	Result    bool      `json:"result"`
	Timestamp time.Time `json:"timestamp"`
}

func (a *App) sendEvaluationEvent(userID, flagName string, result bool) {
	event := EvaluationEvent{
		UserID:    userID,
		FlagName:  flagName,
		Result:    result,
		Timestamp: time.Now().UTC(),
	}

	body, err := json.Marshal(event)
	if err != nil {
		log.Printf("Erro ao serializar evento de avaliação: %v", err)
		return
	}

	if a.EventPublisher == nil {
		log.Printf("[ANALYTICS_QUEUE_DISABLED] Evento: %s", body)
		return
	}

	if err := a.EventPublisher.Publish(ctx, string(body)); err != nil {
		log.Printf("Erro ao enviar evento para OCI Queue: %v", err)
		return
	}

	log.Printf("Evento de avaliação enviado para OCI Queue (Flag: %s)", flagName)
}
